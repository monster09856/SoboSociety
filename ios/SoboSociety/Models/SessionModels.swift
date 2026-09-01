import Foundation

public struct ClassTypeDTO: Codable, Identifiable, Sendable {
    public let id: Int
    public let ad: String
    public let sure_dk: Int?
    public let renk: String?
    public let renk_kodu: String?

    public var displayColorHex: String {
        renk ?? renk_kodu ?? "#A2846F"
    }

    public init(id: Int, ad: String, sure_dk: Int? = 50, renk: String? = nil, renk_kodu: String? = nil) {
        self.id = id
        self.ad = ad
        self.sure_dk = sure_dk
        self.renk = renk
        self.renk_kodu = renk_kodu
    }
}

public struct InstructorDTO: Codable, Identifiable, Sendable {
    public let id: Int
    public let ad: String
    public let biyografi: String?
    public let foto_url: String?

    public init(id: Int, ad: String, biyografi: String? = nil, foto_url: String? = nil) {
        self.id = id
        self.ad = ad
        self.biyografi = biyografi
        self.foto_url = foto_url
    }
}

public struct ClassSessionDTO: Codable, Identifiable, Sendable {
    public let id: Int
    public let baslangic: String?
    public let baslangic_utc: String?
    public let bitis_utc: String?
    public let kontenjan: Int?
    public let toplam_kontenjan: Int?
    public let dolu_sayi: Int?
    public let doluluk: Int?
    public let durum: String?
    public let rezerve_edilebilir: Bool?
    public let uye_rezervasyonu_var: Bool?
    public let uye_bekleme_sirasinda: Bool?
    public let class_type: ClassTypeDTO?
    public let ders_tipi: ClassTypeDTO?
    public let instructor: InstructorDTO?
    public let egitmen: InstructorDTO?

    public var resolvedClassType: ClassTypeDTO {
        class_type ?? ders_tipi ?? ClassTypeDTO(id: 0, ad: "Reformer Pilates")
    }

    public var resolvedInstructor: InstructorDTO {
        instructor ?? egitmen ?? InstructorDTO(id: 0, ad: "Eğitmen")
    }

    public var resolvedKontenjan: Int {
        kontenjan ?? toplam_kontenjan ?? 10
    }

    public var resolvedDoluSayi: Int {
        dolu_sayi ?? doluluk ?? 0
    }

    public var kalanYer: Int {
        max(0, resolvedKontenjan - resolvedDoluSayi)
    }

    public var startFormatted: String {
        let isoStr = baslangic ?? baslangic_utc ?? ""
        if isoStr.contains("T") {
            let parts = isoStr.components(separatedBy: "T")
            if parts.count > 1 {
                let timeParts = parts[1].components(separatedBy: ":")
                if timeParts.count >= 2 {
                    return "\(timeParts[0]):\(timeParts[1])"
                }
            }
        }
        return isoStr
    }

    public init(
        id: Int,
        baslangic: String? = nil,
        baslangic_utc: String? = nil,
        bitis_utc: String? = nil,
        kontenjan: Int? = 10,
        toplam_kontenjan: Int? = 10,
        dolu_sayi: Int? = 0,
        doluluk: Int? = 0,
        durum: String? = "aktif",
        rezerve_edilebilir: Bool? = true,
        uye_rezervasyonu_var: Bool? = false,
        uye_bekleme_sirasinda: Bool? = false,
        class_type: ClassTypeDTO? = nil,
        ders_tipi: ClassTypeDTO? = nil,
        instructor: InstructorDTO? = nil,
        egitmen: InstructorDTO? = nil
    ) {
        self.id = id
        self.baslangic = baslangic
        self.baslangic_utc = baslangic_utc
        self.bitis_utc = bitis_utc
        self.kontenjan = kontenjan
        self.toplam_kontenjan = toplam_kontenjan
        self.dolu_sayi = dolu_sayi
        self.doluluk = doluluk
        self.durum = durum
        self.rezerve_edilebilir = rezerve_edilebilir
        self.uye_rezervasyonu_var = uye_rezervasyonu_var
        self.uye_bekleme_sirasinda = uye_bekleme_sirasinda
        self.class_type = class_type
        self.ders_tipi = ders_tipi
        self.instructor = instructor
        self.egitmen = egitmen
    }
}
