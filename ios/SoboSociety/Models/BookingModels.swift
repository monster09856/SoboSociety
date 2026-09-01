import Foundation

public struct BookingCreateRequest: Encodable, Sendable {
    public let session_id: Int
    public init(session_id: Int) { self.session_id = session_id }
}

public struct BookingResponse: Codable, Identifiable, Sendable {
    public let id: Int
    public let member_id: Int?
    public let session_id: Int?
    public let oturum_id: Int?
    public let durum: String
    public let kaynak: String?
    public let olusturuldu_utc: String?
    public let session: ClassSessionDTO?

    public var resolvedSessionId: Int {
        session_id ?? oturum_id ?? 0
    }

    public init(
        id: Int,
        member_id: Int? = nil,
        session_id: Int? = nil,
        oturum_id: Int? = nil,
        durum: String,
        kaynak: String? = nil,
        olusturuldu_utc: String? = nil,
        session: ClassSessionDTO? = nil
    ) {
        self.id = id
        self.member_id = member_id
        self.session_id = session_id
        self.oturum_id = oturum_id
        self.durum = durum
        self.kaynak = kaynak
        self.olusturuldu_utc = olusturuldu_utc
        self.session = session
    }
}

public struct WaitlistCreateRequest: Encodable, Sendable {
    public let session_id: Int
    public init(session_id: Int) { self.session_id = session_id }
}

public struct WaitlistResponse: Codable, Identifiable, Sendable {
    public let id: Int
    public let member_id: Int
    public let session_id: Int
    public let sira: Int
    public let kullanildi: Bool
}
