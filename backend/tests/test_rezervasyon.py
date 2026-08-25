import asyncio
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.models import (
    Booking, BookingDurumu, BookingKaynagi, ClassSession, ClassType,
    CreditLedger, Instructor, LedgerTipi, Member, MemberPackage, Package,
    Room, SessionDurumu,
)
from app.services.hatalar import (
    DersBaslamis, DersDolu, DersIptalEdilmis, KayitBulunamadi,
    YetersizKredi, ZatenRezerve,
)
from app.services.kredi import bakiye, hareket_ekle, paket_tanimla
from app.services.rezervasyon import rezerve_et

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)
# Rezervasyon anı dersten önce olmalı; `rezerve_et` başlamış derse kayıt almaz.
REZERVASYON_ANI = DERS_ANI - timedelta(hours=8)


async def _senaryo(db, *, kontenjan: int = 2, kredi_ver: bool = True):
    uye = Member(telefon="+905316033080", ad="Selin")
    tip = ClassType(ad="Barre", kontenjan=kontenjan, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, tip, egitmen, salon, paket])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI,
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=kontenjan,
    )
    db.add(oturum)
    await db.flush()

    if kredi_ver:
        await paket_tanimla(
            db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
        )
    return uye, oturum, paket


async def test_rezervasyon_dolu_sayiyi_artirir_ve_kredi_duser(db):
    uye, oturum, _ = await _senaryo(db)

    kayit = await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)

    await db.refresh(oturum)
    assert kayit.durum == BookingDurumu.BOOKED
    assert oturum.dolu_sayi == 1
    assert await bakiye(db, uye.id) == 7


async def test_kontenjan_dolunca_rezervasyon_reddedilir(db):
    uye, oturum, paket = await _senaryo(db, kontenjan=1)

    await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)

    baskasi = Member(telefon="+905321112233", ad="Ece")
    db.add(baskasi)
    await db.flush()
    await paket_tanimla(db, member_id=baskasi.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    with pytest.raises(DersDolu):
        await rezerve_et(db, member_id=baskasi.id, session_id=oturum.id, now=REZERVASYON_ANI)


async def test_kredisi_olmayan_uye_rezervasyon_yapamaz(db):
    uye, oturum, _ = await _senaryo(db, kredi_ver=False)

    with pytest.raises(YetersizKredi):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)

    await db.refresh(oturum)
    # Kredi kontrolü kontenjan artışından ÖNCE olmalı — reddedilen istek
    # kontenjandan yer çalmamalı
    assert oturum.dolu_sayi == 0


async def test_ayni_derse_iki_kez_rezervasyon_yapilamaz(db):
    uye, oturum, _ = await _senaryo(db)

    await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)

    with pytest.raises(ZatenRezerve):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)


async def test_iptal_edilmis_derse_rezervasyon_yapilamaz(db):
    uye, oturum, _ = await _senaryo(db)
    oturum.durum = SessionDurumu.IPTAL
    await db.flush()

    with pytest.raises(DersIptalEdilmis):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)


async def test_son_yere_ayni_anda_basan_iki_uyeden_yalniz_biri_kazanir(temiz_db):
    """Kontenjan yarışının gerçek sınaması.

    İki ayrı veritabanı bağlantısı son yer için aynı anda yarışır.
    PostgreSQL READ COMMITTED'da ikinci UPDATE birincinin satır kilidini
    bekler ve commit sonrası WHERE koşulunu YENİDEN değerlendirir; bu yüzden
    son yer iki kez satılamaz.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=1, sure_dk=50)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        selin = Member(telefon="+905316033080", ad="Selin")
        ece = Member(telefon="+905321112233", ad="Ece")
        hazirlik.add_all([tip, egitmen, salon, paket, selin, ece])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=DERS_ANI,
            class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=1,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        for uye in (selin, ece):
            await paket_tanimla(
                hazirlik, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
            )

        oturum_id, selin_id, ece_id = oturum.id, selin.id, ece.id
        await hazirlik.commit()

    async def dene(member_id: int) -> str:
        async with temiz_db() as oturum_db:
            try:
                await rezerve_et(oturum_db, member_id=member_id, session_id=oturum_id, now=REZERVASYON_ANI)
                await oturum_db.commit()
                return "kazandi"
            except DersDolu:
                await oturum_db.rollback()
                return "doldu"

    sonuclar = await asyncio.gather(dene(selin_id), dene(ece_id))

    assert sorted(sonuclar) == ["doldu", "kazandi"]

    async with temiz_db() as kontrol:
        guncel = await kontrol.get(ClassSession, oturum_id)
        assert guncel.dolu_sayi == 1

        kayitlar = await kontrol.execute(
            select(Booking).where(Booking.session_id == oturum_id)
        )
        assert len(list(kayitlar.scalars())) == 1


async def test_ayni_uye_iki_derse_ayni_anda_basarsa_krediden_fazlasini_alamaz(temiz_db):
    """1 kredisi kalan üye iki FARKLI derse aynı anda basarsa yalnız biri geçer.

    Kontenjan yarışı atomik UPDATE ile çözüldü; bu test aynı korumanın
    kredi ekseninde de olduğunu doğrular. Üye satırı FOR UPDATE ile
    kilitlendiği için istekler serileşir.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=5, sure_dk=50)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        uye = Member(telefon="+905316033080", ad="Selin")
        hazirlik.add_all([tip, egitmen, salon, uye])
        await hazirlik.flush()

        oturum1 = ClassSession(
            baslangic=DERS_ANI,
            class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=5,
        )
        oturum2 = ClassSession(
            baslangic=DERS_ANI + timedelta(hours=2),
            class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=5,
        )
        hazirlik.add_all([oturum1, oturum2])
        await hazirlik.flush()

        await hareket_ekle(
            hazirlik, member_id=uye.id, tip=LedgerTipi.ADMIN_ADJUST,
            miktar=1, sebep="test",
        )

        uye_id, oturum1_id, oturum2_id = uye.id, oturum1.id, oturum2.id
        await hazirlik.commit()

    async def dene(session_id: int) -> str:
        async with temiz_db() as oturum_db:
            try:
                await rezerve_et(oturum_db, member_id=uye_id, session_id=session_id, now=REZERVASYON_ANI)
                await oturum_db.commit()
                return "kazandi"
            except YetersizKredi:
                await oturum_db.rollback()
                return "yetersiz"

    sonuclar = await asyncio.gather(dene(oturum1_id), dene(oturum2_id))

    assert sorted(sonuclar) == ["kazandi", "yetersiz"]

    async with temiz_db() as kontrol:
        assert await bakiye(kontrol, uye_id) == 0

        kayitlar = await kontrol.execute(
            select(Booking).where(Booking.member_id == uye_id)
        )
        assert len(list(kayitlar.scalars())) == 1


async def test_ayni_derse_iki_sekmeden_ayni_anda_basmak_domain_hatasi_verir(temiz_db):
    """Aynı derse iki eşzamanlı istek: yalnız biri geçer, diğeri SoboHata alır.

    NOT: Bu test IntegrityError yolunu SINAMAZ. Üye satırı FOR UPDATE ile
    kilitli olduğu için iki istek serileşir ve ikincisi kısmi unique
    index'e hiç ulaşmadan ön kontroldeki `ZatenRezerve`'ye takılır.
    (İnceleme bunu mutasyon testiyle kanıtladı: savepoint bloğu tamamen
    silindiğinde bu dosya 3/3 çalıştırmada yeşil kalıyordu.) Savepoint
    bloğunu asıl sınayan test
    `test_uye_kilidini_baypas_eden_cift_kayit_domain_hatasi_verir`.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=5, sure_dk=50)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        uye = Member(telefon="+905316033080", ad="Selin")
        hazirlik.add_all([tip, egitmen, salon, paket, uye])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=DERS_ANI,
            class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=5,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        await paket_tanimla(
            hazirlik, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
        )

        uye_id, oturum_id = uye.id, oturum.id
        await hazirlik.commit()

    async def dene() -> str:
        async with temiz_db() as oturum_db:
            try:
                await rezerve_et(oturum_db, member_id=uye_id, session_id=oturum_id, now=REZERVASYON_ANI)
                await oturum_db.commit()
                return "kazandi"
            except ZatenRezerve:
                await oturum_db.rollback()
                return "zaten_rezerve"

    sonuclar = await asyncio.gather(dene(), dene())

    assert sorted(sonuclar) == ["kazandi", "zaten_rezerve"]

    async with temiz_db() as kontrol:
        guncel = await kontrol.get(ClassSession, oturum_id)
        assert guncel.dolu_sayi == 1

        kayitlar = await kontrol.execute(
            select(Booking).where(Booking.session_id == oturum_id)
        )
        assert len(list(kayitlar.scalars())) == 1


async def test_kaynak_parametresi_kayda_yazilir(db):
    """kaynak=ADMIN ile yapılan rezervasyon panelden geldiği anlaşılsın."""
    uye, oturum, _ = await _senaryo(db)

    kayit = await rezerve_et(
        db, member_id=uye.id, session_id=oturum.id,
        now=REZERVASYON_ANI, kaynak=BookingKaynagi.ADMIN,
    )

    assert kayit.kaynak == "admin"


async def test_baslamis_derse_rezervasyon_yapilamaz(db):
    """Geçmiş derse kayıt olup kredi yakmak mümkün olmamalı.

    Kontrol kredi ve kontenjan kontrollerinden ÖNCE: reddedilen istek
    ne kontenjandan yer çalmalı ne de krediye dokunmalı.
    """
    uye, oturum, _ = await _senaryo(db)

    with pytest.raises(DersBaslamis):
        await rezerve_et(
            db, member_id=uye.id, session_id=oturum.id,
            now=DERS_ANI + timedelta(minutes=1),
        )

    await db.refresh(oturum)
    assert oturum.dolu_sayi == 0
    assert await bakiye(db, uye.id) == 8


async def test_tam_ders_aninda_rezervasyon_yapilamaz(db):
    """Sınır: `now == baslangic` anında ders başlamış sayılır."""
    uye, oturum, _ = await _senaryo(db)

    with pytest.raises(DersBaslamis):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=DERS_ANI)


async def test_booking_satiri_hangi_paketten_dusuldugunu_yazar(db):
    """A2: tüketimin hangi pakete ait olduğu ŞİMDİ yazılmalı.

    Yazılmazsa "bu paketten kaç ders kaldı" sorusu sonradan cevaplanamaz
    ve geçmiş satırların atfı geriye dönük kurtarılamaz.
    """
    uye, oturum, _ = await _senaryo(db)

    kayit = await rezerve_et(
        db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI
    )

    uye_paketi = (
        await db.execute(select(MemberPackage).where(MemberPackage.member_id == uye.id))
    ).scalar_one()
    satir = (
        await db.execute(
            select(CreditLedger).where(
                CreditLedger.booking_id == kayit.id,
                CreditLedger.tip == LedgerTipi.BOOKING,
            )
        )
    ).scalar_one()

    assert satir.member_package_id == uye_paketi.id


async def test_paketi_olmayan_uyenin_booking_satiri_paketsiz_yazilir(db):
    """Admin düzeltmesiyle kredi verilmiş ama paketi olmayan üye geçerlidir."""
    uye, oturum, _ = await _senaryo(db, kredi_ver=False)
    await hareket_ekle(
        db, member_id=uye.id, tip=LedgerTipi.ADMIN_ADJUST, miktar=1,
        sebep="Deneme dersi hediye edildi",
    )

    kayit = await rezerve_et(
        db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI
    )

    satir = (
        await db.execute(
            select(CreditLedger).where(
                CreditLedger.booking_id == kayit.id,
                CreditLedger.tip == LedgerTipi.BOOKING,
            )
        )
    ).scalar_one()
    assert satir.member_package_id is None


async def test_bulunmayan_ders_domain_hatasi_verir(db):
    """B1: `ValueError` değil `SoboHata` — API katmanı 500 değil 4xx dönmeli."""
    uye, _, _ = await _senaryo(db)

    with pytest.raises(KayitBulunamadi):
        await rezerve_et(
            db, member_id=uye.id, session_id=999999, now=REZERVASYON_ANI
        )


async def test_uye_kilidini_baypas_eden_cift_kayit_domain_hatasi_verir(db):
    """D3: savepoint/`IntegrityError` bloğunun gerçekten çalıştığını kanıtlar.

    `rezerve_et`'in NORMAL akışında bu blok ulaşılamaz: üye satırı
    FOR UPDATE ile kilitli olduğu için eşzamanlı çağrılar serileşir ve
    ikincisi ön kontrole (`ZatenRezerve`) takılır. Ayrıca kilit tutulurken
    başka bir transaction aynı üye için `bookings` INSERT'i bile yapamaz —
    FK, `members` üzerinde FOR KEY SHARE ister ve FOR UPDATE ile çatışır.

    Blok yine de gereklidir: kilidi HİÇ ALMAYAN bir kod yolu (veri taşıma,
    admin toplu kayıt) aynı satırı yazarsa kısmi unique index tetiklenir.
    Burada o yolu, ön kontrolün göremeyeceği bekleyen bir INSERT ile taklit
    ediyoruz — `no_autoflush` sayesinde satır ön kontrol SELECT'i sırasında
    veritabanına yazılmaz, akış savepoint bloğuna ULAŞIR ve orada ham
    IntegrityError üretir.
    """
    uye, oturum, _ = await _senaryo(db)

    kacak = Booking(
        member_id=uye.id, session_id=oturum.id, durum=BookingDurumu.BOOKED,
        kaynak=BookingKaynagi.ADMIN,
    )
    db.add(kacak)

    with db.no_autoflush:
        with pytest.raises(ZatenRezerve):
            await rezerve_et(
                db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI
            )
