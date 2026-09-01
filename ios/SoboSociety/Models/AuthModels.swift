import Foundation

public struct OTPSendRequest: Encodable, Sendable {
    public let telefon: String
    public init(telefon: String) { self.telefon = telefon }
}

public struct OTPSendResponse: Decodable, Sendable {
    public let mesaj: String
    public let telefon: String
}

public struct OTPVerifyRequest: Encodable, Sendable {
    public let telefon: String
    public let kod: String
    public init(telefon: String, kod: String) {
        self.telefon = telefon
        self.kod = kod
    }
}

public struct TokenResponse: Decodable, Sendable {
    public let access_token: String
    public let token_type: String
}

public struct MemberMeResponse: Codable, Identifiable, Sendable {
    public let id: Int
    public let ad: String?
    public let ad_soyad: String?
    public let telefon: String
    public let is_admin: Bool?
    public let aktif: Bool?

    public var displayName: String {
        ad_soyad ?? ad ?? "Üye"
    }
}
