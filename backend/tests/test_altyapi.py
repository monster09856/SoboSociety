from sqlalchemy import text


async def test_veritabani_baglantisi_calisiyor(db):
    sonuc = await db.execute(text("SELECT 1"))
    assert sonuc.scalar_one() == 1
