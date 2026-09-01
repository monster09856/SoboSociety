import Foundation

public struct MemberSummaryResponse: Codable, Sendable {
    public let id: Int?
    public let ad: String?
    public let telefon: String?
    public let bakiye: Int
    public let aktif_rezervasyonlar: [BookingResponse]?
    public let gecmis_rezervasyonlar: [BookingResponse]?
    public let uye: MemberMeResponse?

    public var displayAd: String {
        ad ?? uye?.ad_soyad ?? uye?.ad ?? telefon ?? "Değerli Üyemiz"
    }

    public var displayTelefon: String {
        telefon ?? uye?.telefon ?? ""
    }

    public init(
        id: Int? = nil,
        ad: String? = nil,
        telefon: String? = nil,
        bakiye: Int = 0,
        aktif_rezervasyonlar: [BookingResponse]? = nil,
        gecmis_rezervasyonlar: [BookingResponse]? = nil,
        uye: MemberMeResponse? = nil
    ) {
        self.id = id
        self.ad = ad
        self.telefon = telefon
        self.bakiye = bakiye
        self.aktif_rezervasyonlar = aktif_rezervasyonlar
        self.gecmis_rezervasyonlar = gecmis_rezervasyonlar
        self.uye = uye
    }
}
