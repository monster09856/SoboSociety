from datetime import UTC, datetime

import pytest
from sqlalchemy.exc import IntegrityError

from app.models import ClassSession, ClassType, Instructor, Member, Room


async def test_uye_kaydedilir_ve_varsayilanlar_dogru(db):
    uye = Member(telefon="+905316033080", ad="Selin")
    db.add(uye)
    await db.flush()

    assert uye.id is not None
    assert uye.aktif is True
    # Katılımcı görünürlüğü rızası varsayılan olarak KAPALI olmalı
    assert uye.katilimci_gorunurluk_onay is False
    assert uye.kvkk_onay_at is None


async def test_ayni_telefon_iki_kez_kaydedilemez(db):
    db.add(Member(telefon="+905316033080", ad="Selin"))
    await db.flush()

    db.add(Member(telefon="+905316033080", ad="Selin Y."))
    with pytest.raises(IntegrityError):
        await db.flush()


async def _program_kur(db, *, kontenjan: int = 8):
    tip = ClassType(ad="Barre", kontenjan=kontenjan, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    db.add_all([tip, egitmen, salon])
    await db.flush()
    return tip, egitmen, salon


async def test_ayni_salonda_ayni_anda_iki_ders_olamaz(db):
    tip, egitmen, salon = await _program_kur(db)
    an = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)

    db.add(ClassSession(
        baslangic=an, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    ))
    await db.flush()

    db.add(ClassSession(
        baslangic=an, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    ))
    with pytest.raises(IntegrityError):
        await db.flush()


async def test_dolu_sayi_kontenjani_asamaz(db):
    tip, egitmen, salon = await _program_kur(db, kontenjan=2)

    db.add(ClassSession(
        baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=2, dolu_sayi=3,
    ))
    with pytest.raises(IntegrityError):
        await db.flush()


async def test_kontenjan_snapshot_ders_tipinden_bagimsiz(db):
    """Ders tipinin kontenjanı düşse bile açılmış oturumun kontenjanı sabit kalır."""
    tip, egitmen, salon = await _program_kur(db, kontenjan=8)
    oturum = ClassSession(
        baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=tip.kontenjan,
    )
    db.add(oturum)
    await db.flush()

    tip.kontenjan = 6
    await db.flush()
    await db.refresh(oturum)

    assert oturum.kontenjan == 8
