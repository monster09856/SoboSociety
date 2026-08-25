class SoboHata(Exception):
    """Tüm domain hatalarının kökü. API katmanı bunu yakalayıp 4xx'e çevirir."""


class GecersizTelefon(SoboHata):
    pass


class YetersizKredi(SoboHata):
    pass


class DersDolu(SoboHata):
    pass


class DersIptalEdilmis(SoboHata):
    pass


class ZatenRezerve(SoboHata):
    pass


class ZatenIptal(SoboHata):
    pass


class DersDoluDegil(SoboHata):
    pass


class TeklifSuresiDolmus(SoboHata):
    pass


class ZatenSirada(SoboHata):
    pass


class DersBaslamis(SoboHata):
    """Ders başladıktan sonra rezervasyon/sıra kaydı açılamaz."""


class DersBaslamamis(SoboHata):
    """Ders başlamadan yoklama alınamaz — geri alınamaz hasar üretir."""


class KayitBulunamadi(SoboHata):
    """Servisin ihtiyaç duyduğu satır yok.

    `ValueError` değil: API katmanı domain hatalarını `SoboHata` üzerinden
    tanır ve 4xx'e çevirir. `ValueError` olarak kalsaydı "ders bulunamadı"
    gibi tamamen normal bir istemci hatası 500 dönerdi.
    """


class GecersizHareket(SoboHata):
    """Ledger satırı domain kurallarını çiğniyor (ör. boş sebep)."""
