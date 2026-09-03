import Foundation

public struct AttendeeResponse: Codable, Identifiable, Sendable {
    public var id: Int { booking_id }
    public let booking_id: Int
    public let member_id: Int
    public let ad: String
    public let telefon: String
    public let durum: String

    public init(booking_id: Int, member_id: Int, ad: String, telefon: String, durum: String) {
        self.booking_id = booking_id
        self.member_id = member_id
        self.ad = ad
        self.telefon = telefon
        self.durum = durum
    }
}

public struct TodaySessionResponse: Codable, Identifiable, Sendable {
    public let id: Int
    public let baslangic: String
    public let kontenjan: Int
    public let dolu_sayi: Int
    public let durum: String
    public let class_type: ClassTypeDTO?
    public let instructor: InstructorDTO?
    public let katilimcilar: [AttendeeResponse]?
    public let attendees: [AttendeeResponse]?

    public var resolvedAttendees: [AttendeeResponse] {
        katilimcilar ?? attendees ?? []
    }

    public var startFormatted: String {
        if baslangic.contains("T") {
            let parts = baslangic.components(separatedBy: "T")
            if parts.count > 1 {
                let timeParts = parts[1].components(separatedBy: ":")
                if timeParts.count >= 2 {
                    return "\(timeParts[0]):\(timeParts[1])"
                }
            }
        }
        return baslangic
    }

    public init(
        id: Int,
        baslangic: String,
        kontenjan: Int,
        dolu_sayi: Int,
        durum: String,
        class_type: ClassTypeDTO? = nil,
        instructor: InstructorDTO? = nil,
        katilimcilar: [AttendeeResponse]? = nil,
        attendees: [AttendeeResponse]? = nil
    ) {
        self.id = id
        self.baslangic = baslangic
        self.kontenjan = kontenjan
        self.dolu_sayi = dolu_sayi
        self.durum = durum
        self.class_type = class_type
        self.instructor = instructor
        self.katilimcilar = katilimcilar
        self.attendees = attendees
    }
}

public struct QuickBookingRequest: Encodable, Sendable {
    public let telefon: String
    public let session_id: Int
    public let ad: String?
    public let package_id: Int?

    public init(telefon: String, session_id: Int, ad: String? = nil, package_id: Int? = nil) {
        self.telefon = telefon
        self.session_id = session_id
        self.ad = ad
        self.package_id = package_id
    }
}

public struct AttendanceSubmitRequest: Encodable, Sendable {
    public let session_id: Int
    public let gelen_member_ids: [Int]

    public init(session_id: Int, gelen_member_ids: [Int]) {
        self.session_id = session_id
        self.gelen_member_ids = gelen_member_ids
    }
}

public struct AttendanceSubmitResponse: Decodable, Sendable {
    public let gelen: Int
    public let gelmeyen: Int
}

public struct MemberAdminDetailResponse: Codable, Identifiable, Sendable {
    public let id: Int
    public let ad: String
    public let kullanici_adi: String?
    public let telefon: String?
    public let bakiye: Int
    public let aktif: Bool
    public let is_admin: Bool
    public let bel: String?
    public let kalca: String?
    public let sag_ic_bacak: String?
    public let sag_bacak: String?
    public let sol_ic_bacak: String?
    public let sol_bacak: String?
    public let sag_kol: String?
    public let sol_kol: String?
    public let boy: String?
    public let kilo: String?
    public let saglik_notu: String?
    public let aktif_member_package_id: Int?
    public let aktif_paket_adi: String?
    public let paket_bitis_tarihi: String?
    public let kalan_gun_sayisi: Int?
    public let tanimlanan_paketler: [String]?
}
