import pytest
from sqlalchemy.exc import IntegrityError

from app.models import Member


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
