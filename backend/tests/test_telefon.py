import pytest

from app.services.hatalar import GecersizTelefon
from app.services.telefon import normalize_telefon


@pytest.mark.parametrize(
    "ham",
    [
        "0531 603 30 80",
        "+90 531 603 30 80",
        "531 603 30 80",
        "05316033080",
        "+905316033080",
        "90 531 603 30 80",
        "(0531) 603-30-80",
    ],
)
def test_ayni_numaranin_tum_yazimlari_ayni_sonuca_gider(ham):
    assert normalize_telefon(ham) == "+905316033080"


@pytest.mark.parametrize(
    "ham",
    [
        "",
        "123",
        "0531 603 30 8",       # bir hane eksik
        "0531 603 30 800",     # bir hane fazla
        "abc",
        "+1 555 123 4567",     # Türkiye dışı
        "0231 603 30 80",      # cep numarası 5 ile başlamalı
    ],
)
def test_gecersiz_numaralar_reddedilir(ham):
    with pytest.raises(GecersizTelefon):
        normalize_telefon(ham)
