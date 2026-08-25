import re

from app.services.hatalar import GecersizTelefon

_RAKAM_DISI = re.compile(r"\D")


def normalize_telefon(ham: str) -> str:
    """Türkiye cep numarasını `+90XXXXXXXXXX` biçimine getirir.

    Üye kaydı üç ayrı yerden geliyor (üye kendi, eğitmen paneli, DM'den elle
    giriş). Normalize edilmezse aynı kişi için birden çok kayıt oluşur ve
    kredi bakiyesi bölünür — bu yüzden telefon tek doğrulama noktasıdır.
    """
    if not ham:
        raise GecersizTelefon("Telefon numarası boş")

    rakamlar = _RAKAM_DISI.sub("", ham)

    # Ülke kodu ve baştaki sıfırı ayıkla, geriye 10 hane kalmalı: 5XXXXXXXXX
    if rakamlar.startswith("90"):
        rakamlar = rakamlar[2:]
    elif rakamlar.startswith("0"):
        rakamlar = rakamlar[1:]

    if len(rakamlar) != 10 or not rakamlar.startswith("5"):
        raise GecersizTelefon(f"Geçerli bir Türkiye cep numarası değil: {ham}")

    return f"+90{rakamlar}"
