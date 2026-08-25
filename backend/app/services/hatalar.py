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
