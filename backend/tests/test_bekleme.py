import asyncio
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select, text

from app.models import (
    ClassSession, ClassType, Instructor, Member, Package, Room,
    SessionDurumu, WaitlistEntry,
)
from app.services.bekleme import (
    TEKLIF_SURESI_DK, siraya_gir, sirayi_ilerlet, teklifi_kullan,
)
from app.services.hatalar import (
    DersBaslamis, DersDoluDegil, DersIptalEdilmis, TeklifSuresiDolmus,
    ZatenRezerve, ZatenSirada,
)
from app.services.iptal import iptal_et
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)
# Rezervasyon/sıra anı dersten önce olmalı; başlamış derse kayıt alınmaz.
REZERVASYON_ANI = DERS_ANI - timedelta(hours=14)


async def _dolu_ders(db):
    """Kontenjanı 1 olan ve dolu bir ders; ayrıca sıraya girecek iki üye."""
    tip = ClassType(ad="Barre", kontenjan=1, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    selin = Member(telefon="+905316033080", ad="Selin")
    ece = Member(telefon="+905321112233", ad="Ece")
    zeynep = Member(telefon="+905334445566", ad="Zeynep")
    db.add_all([tip, egitmen, salon, paket, selin, ece, zeynep])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=1,
    )
    db.add(oturum)
    await db.flush()

    for uye in (selin, ece, zeynep):
        await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    kayit = await rezerve_et(db, member_id=selin.id, session_id=oturum.id, now=REZERVASYON_ANI)
    return oturum, selin, ece, zeynep, kayit


async def test_dolu_derse_siraya_girilir(db):
    oturum, _, ece, _, _ = await _dolu_ders(db)

    kayit = await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    assert kayit.sira == 1
    assert kayit.teklif_bitis is None
    assert kayit.kullanildi is False


async def test_sira_numaralari_girilme_sirasina_gore_artar(db):
    oturum, _, ece, zeynep, _ = await _dolu_ders(db)

    birinci = await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)
    ikinci = await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id, now=REZERVASYON_ANI)

    assert (birinci.sira, ikinci.sira) == (1, 2)


async def test_dolu_olmayan_derse_siraya_girilemez(db):
    oturum, selin, ece, _, kayit = await _dolu_ders(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=14))

    with pytest.raises(DersDoluDegil):
        await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)


async def test_ayni_derse_iki_kez_siraya_girilemez(db):
    oturum, _, ece, _, _ = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    with pytest.raises(ZatenSirada):
        await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)


async def test_yer_acilinca_siradakine_teklif_verilir(db):
    oturum, _, ece, zeynep, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)
    await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    assert teklif is not None
    assert teklif.member_id == ece.id
    assert teklif.teklif_bitis == an + timedelta(minutes=TEKLIF_SURESI_DK)


async def test_derse_yakinsa_teklif_suresi_kisalir(db):
    """Ders 10 dakika sonra başlıyorsa 20 dakika beklemek yeri boşa harcar."""
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(minutes=10)
    await iptal_et(db, booking_id=kayit.id, now=an, is_admin=True)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    assert teklif.teklif_bitis == DERS_ANI


async def test_teklif_kullanilinca_rezervasyon_olusur(db):
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    yeni = await teklifi_kullan(db, entry_id=teklif.id, now=an + timedelta(minutes=5))

    assert yeni.member_id == ece.id
    await db.refresh(oturum)
    assert oturum.dolu_sayi == 1
    assert await bakiye(db, ece.id) == 7


async def test_suresi_dolmus_teklif_kullanilamaz(db):
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    with pytest.raises(TeklifSuresiDolmus):
        await teklifi_kullan(
            db, entry_id=teklif.id, now=an + timedelta(minutes=TEKLIF_SURESI_DK + 1)
        )


async def test_teklif_suresi_dolunca_sira_bir_sonrakine_gecer(db):
    oturum, _, ece, zeynep, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)
    await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    sonraki = await sirayi_ilerlet(
        db, session_id=oturum.id, now=an + timedelta(minutes=TEKLIF_SURESI_DK + 1)
    )

    assert sonraki is not None
    assert sonraki.member_id == zeynep.id


async def test_bos_sirada_ilerletmek_none_doner(db):
    oturum, _, _, _, kayit = await _dolu_ders(db)
    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)

    assert await sirayi_ilerlet(db, session_id=oturum.id, now=an) is None


async def test_tam_sinirda_teklif_hala_gecerlidir(db):
    """`sirayi_ilerlet` ile `teklifi_kullan` sınırda hizalı olmalı.

    `now == teklif_bitis` anında teklif hâlâ AÇIK sayılmalı — aksi halde
    `sirayi_ilerlet` teklifi dolmuş sayıp sıradakine yeni teklif verirken
    `teklifi_kullan` ilk kişiye hâlâ izin verir ve aynı yer için iki
    geçerli teklif oluşur.
    """
    oturum, _, ece, zeynep, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)
    await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    ilk_teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    tam_sinir = ilk_teklif.teklif_bitis
    tekrar = await sirayi_ilerlet(db, session_id=oturum.id, now=tam_sinir)

    assert tekrar.id == ilk_teklif.id
    assert tekrar.member_id == ece.id


async def test_ders_baslamissa_sira_ilerletilemez(db):
    """Ders başlamış/geçmişse bekleme listesi ilerletilmemeli.

    Aksi halde ardışık çağrılar sırayı sessizce yakar: her çağrı
    kullanılamaz (geçmişte biten) bir teklif verip sıradaki kişiye geçer.
    """
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)

    assert await sirayi_ilerlet(db, session_id=oturum.id, now=DERS_ANI) is None

    sonuc = await db.execute(
        select(WaitlistEntry).where(
            WaitlistEntry.member_id == ece.id, WaitlistEntry.session_id == oturum.id
        )
    )
    assert sonuc.scalar_one().teklif_bitis is None


async def test_ayni_anda_siraya_giren_iki_uye_farkli_sira_numarasi_alir(temiz_db):
    """Sıra numarası üretimi yarışa dayanıklı olmalı.

    class_sessions satırı FOR UPDATE ile kilitlendiği için `MAX(sira) + 1`
    serileşir; iki üye aynı numarayı alamaz.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=1, sure_dk=50)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        selin = Member(telefon="+905316033080", ad="Selin")
        ece = Member(telefon="+905321112233", ad="Ece")
        zeynep = Member(telefon="+905334445566", ad="Zeynep")
        hazirlik.add_all([tip, egitmen, salon, paket, selin, ece, zeynep])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=1,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        for uye in (selin, ece, zeynep):
            await paket_tanimla(
                hazirlik, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
            )

        await rezerve_et(hazirlik, member_id=selin.id, session_id=oturum.id, now=REZERVASYON_ANI)

        oturum_id, ece_id, zeynep_id = oturum.id, ece.id, zeynep.id
        await hazirlik.commit()

    kapi = asyncio.Barrier(2)

    async def dene(member_id: int) -> WaitlistEntry:
        async with temiz_db() as oturum_db:
            # Yarışı gerçekten kurabilmek için iki şey birden gerekiyor:
            # bağlantıyı önceden ısıtmak VE iki görevi tam aynı anda serbest
            # bırakmak. Yalnız biri yapılırsa görevler kayar ve çakışma
            # penceresi kapanır — test kilit silinse bile yeşil kalır.
            await oturum_db.execute(text("SELECT 1"))
            async with asyncio.timeout(10):
                await kapi.wait()
            kayit = await siraya_gir(oturum_db, member_id=member_id, session_id=oturum_id, now=REZERVASYON_ANI)
            await oturum_db.commit()
            return kayit

    kayit_ece, kayit_zeynep = await asyncio.gather(dene(ece_id), dene(zeynep_id))

    assert {kayit_ece.sira, kayit_zeynep.sira} == {1, 2}

    async with temiz_db() as kontrol:
        kayitlar = await kontrol.execute(
            select(WaitlistEntry).where(WaitlistEntry.session_id == oturum_id)
        )
        assert len(list(kayitlar.scalars())) == 2


async def test_baslamis_derse_siraya_girilemez(db):
    """A1: `rezerve_et` ile hizalı — başlamış derse sıra kaydı açılmaz."""
    oturum, _, ece, _, _ = await _dolu_ders(db)

    with pytest.raises(DersBaslamis):
        await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=DERS_ANI)


async def test_zaten_rezerve_olan_uye_siraya_giremez(db):
    """A3: derse kayıtlı üyenin bekleme listesine girmesi domain olarak saçma.

    Ayrıca `iptal_et` ile arasındaki deadlock döngüsünün tetikleyicisiydi.
    """
    oturum, selin, _, _, _ = await _dolu_ders(db)

    with pytest.raises(ZatenRezerve):
        await siraya_gir(
            db, member_id=selin.id, session_id=oturum.id, now=REZERVASYON_ANI
        )


async def test_iptal_edilmis_derse_siraya_girilemez(db):
    """B4: `rezerve_et` `DersIptalEdilmis` fırlatıyor — kavram tek olmalı."""
    oturum, _, ece, _, _ = await _dolu_ders(db)
    oturum.durum = SessionDurumu.IPTAL
    await db.flush()

    with pytest.raises(DersIptalEdilmis):
        await siraya_gir(
            db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI
        )


async def test_iptal_edilmis_derste_sira_ilerletilmez(db):
    """B4: `sirayi_ilerlet` bir sorgulama fonksiyonu — hata değil None döner."""
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    oturum.durum = SessionDurumu.IPTAL
    await db.flush()

    assert await sirayi_ilerlet(db, session_id=oturum.id, now=an) is None

    bekleyen = await db.execute(
        select(WaitlistEntry).where(WaitlistEntry.session_id == oturum.id)
    )
    assert bekleyen.scalar_one().teklif_bitis is None


async def test_ders_doluyken_teklif_acilmaz(db):
    """C1: açılmamış bir yer için üyeye bildirim gitmemeli.

    Kontrol olmadan teklif açılıyor, üye çağrılıyor ve `teklifi_kullan`
    sonra `DersDolu` ile patlıyordu.
    """
    oturum, _, ece, _, _ = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    assert await sirayi_ilerlet(db, session_id=oturum.id, now=REZERVASYON_ANI) is None

    bekleyen = await db.execute(
        select(WaitlistEntry).where(WaitlistEntry.session_id == oturum.id)
    )
    assert bekleyen.scalar_one().teklif_bitis is None


async def test_kullanilmis_teklif_ikinci_kez_kullanilamaz(db):
    """C2: teklifi kullanıp iptal eden üye aynı teklifle yeniden yer alamaz."""
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI)

    an = DERS_ANI - timedelta(hours=14)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    yeni = await teklifi_kullan(db, entry_id=teklif.id, now=an + timedelta(minutes=1))
    await iptal_et(db, booking_id=yeni.id, now=an + timedelta(minutes=2))

    with pytest.raises(TeklifSuresiDolmus):
        await teklifi_kullan(
            db, entry_id=teklif.id, now=an + timedelta(minutes=3)
        )


async def test_iptal_ve_siraya_gir_deadlock_uretmez(temiz_db):
    """A4: kilit sırası ihlali GERÇEK bir deadlock üretiyordu.

    İnceleme şu döngüyü kurup PostgreSQL'den `DeadlockDetectedError` aldı:

        T2 siraya_gir : members[M] FOR UPDATE  -> class_sessions[S] FOR UPDATE
        T1 iptal_et   : class_sessions[S] UPDATE -> members[M] FOR KEY SHARE

    `iptal_et`'in `members` kilidi dolaylıydı: `credit_ledger` INSERT'inin
    FK kontrolü `FOR KEY SHARE` alır. Düzeltmeden sonra `iptal_et` de üye
    satırını EN BAŞTA açıkça kilitler; sıra istisnasız members ->
    class_sessions olur ve döngü kurulamaz.

    Determinizm için T2'nin ilk adımı (üye satırını FOR UPDATE ile
    kilitlemek — `siraya_gir`'in kendi ilk ifadesi) öne alınmıştır;
    aynı transaction içinde tekrar alınması yeniden-girişlidir.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=2, sure_dk=50, iptal_penceresi_saat=6)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        selin = Member(telefon="+905316033080", ad="Selin")
        ece = Member(telefon="+905321112233", ad="Ece")
        hazirlik.add_all([tip, egitmen, salon, paket, selin, ece])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=2,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        for uye in (selin, ece):
            await paket_tanimla(
                hazirlik, member_id=uye.id, package_id=paket.id,
                baslangic=date(2026, 9, 1),
            )
        selin_kayit = await rezerve_et(
            hazirlik, member_id=selin.id, session_id=oturum.id, now=REZERVASYON_ANI
        )
        await rezerve_et(
            hazirlik, member_id=ece.id, session_id=oturum.id, now=REZERVASYON_ANI
        )

        oturum_id, selin_id, booking_id = oturum.id, selin.id, selin_kayit.id
        await hazirlik.commit()

    uye_kilitlendi = asyncio.Event()

    async def sirayi_deneyen() -> str:
        async with temiz_db() as oturum_db:
            await oturum_db.execute(
                select(Member.id).where(Member.id == selin_id).with_for_update()
            )
            uye_kilitlendi.set()
            # T1'in kendi kilit adımına ilerlemesi için pencere aç.
            await asyncio.sleep(0.5)
            try:
                await siraya_gir(
                    oturum_db, member_id=selin_id, session_id=oturum_id,
                    now=REZERVASYON_ANI,
                )
                return "siraya_girdi"
            except ZatenRezerve:
                return "zaten_rezerve"
            finally:
                await oturum_db.rollback()

    async def iptal_eden() -> str:
        async with asyncio.timeout(10):
            await uye_kilitlendi.wait()
        async with temiz_db() as oturum_db:
            await iptal_et(
                oturum_db, booking_id=booking_id, now=DERS_ANI - timedelta(hours=8)
            )
            await oturum_db.commit()
            return "iptal_edildi"

    # Deadlock oluşursa asyncpg `DeadlockDetectedError` fırlatır ve test
    # burada kırmızıya döner.
    sonuclar = await asyncio.gather(sirayi_deneyen(), iptal_eden())

    assert sonuclar == ["zaten_rezerve", "iptal_edildi"]
