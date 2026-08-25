class SoboHata(Exception):
    """Tüm domain hatalarının kökü. API katmanı bunu yakalayıp 4xx'e çevirir."""


class GecersizTelefon(SoboHata):
    pass
