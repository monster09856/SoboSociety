# Sobo Society iOS Mobil Uygulaması & Codemagic Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sobo Society markası için modern SwiftUI (iOS 17+ / Swift Concurrency), Keychain JWT saklama, Canlı Ders Rezervasyonu, Üye Kredi Takibi, Eğitmen 5 Saniyelik DM Hızlı Kayıt paneli ve Codemagic CI/CD otomasyonu (`codemagic.yaml`) içeren iOS uygulamasını inşa etmek.

**Architecture:** SwiftUI View-ViewModel (MVVM) deseni, URLSession `async/await` tabanlı `APIClient`, Keychain güvenli token yönetimi, `@Observable` reaktif durum yönetimi ve Sobo Instagram Marka Kimliği (Ivory, Sand, Espresso, Mocha, Cormorant Garamond / Jost tipografisi).

**Tech Stack:** Swift 6 / SwiftUI (iOS 17+), KeychainServices, URLSession async/await, Codemagic YAML CI/CD.

---

### Task 1: Proje Yapısı, Tema ve Data Modelleri DTO (Models & Theme)

**Files:**
- Create: `ios/SoboSociety/Models/AuthModels.swift`
- Create: `ios/SoboSociety/Models/SessionModels.swift`
- Create: `ios/SoboSociety/Models/BookingModels.swift`
- Create: `ios/SoboSociety/Models/MemberModels.swift`
- Create: `ios/SoboSociety/Theme/SoboTheme.swift`

- [ ] **Step 1: Data Modelleri ve DTO'ları Yazma (`Codable`, `Identifiable`, `Sendable`)**

```swift
// ios/SoboSociety/Models/AuthModels.swift
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

public struct MemberMeResponse: Decodable, Identifiable, Sendable {
    public let id: Int
    public let ad_soyad: String?
    public let telefon: String
    public let is_admin: Bool
    public let aktif: Bool
}
```

```swift
// ios/SoboSociety/Models/SessionModels.swift
import Foundation

public struct ClassTypeDTO: Decodable, Identifiable, Sendable {
    public let id: Int
    public let ad: String
    public let sure_dk: Int
    public let renk_kodu: String?
}

public struct InstructorDTO: Decodable, Identifiable, Sendable {
    public let id: Int
    public let ad: String
}

public struct ClassSessionDTO: Decodable, Identifiable, Sendable {
    public let id: Int
    public let ders_tipi: ClassTypeDTO
    public let egitmen: InstructorDTO
    public let baslangic_utc: String
    public let bitis_utc: String
    public let toplam_kontenjan: Int
    public let doluluk: Int
    public let rezerve_edilebilir: Bool
    public let uye_rezervasyonu_var: Bool
    public let uye_bekleme_sirasinda: Bool

    public var kalanYer: Int {
        max(0, toplam_kontenjan - doluluk)
    }
}
```

```swift
// ios/SoboSociety/Models/BookingModels.swift
import Foundation

public struct BookingCreateRequest: Encodable, Sendable {
    public let oturum_id: Int
    public init(oturum_id: Int) { self.oturum_id = oturum_id }
}

public struct BookingResponse: Decodable, Identifiable, Sendable {
    public let id: Int
    public let member_id: Int
    public let oturum_id: Int
    public let durum: String
    public let olusturuldu_utc: String
}
```

```swift
// ios/SoboSociety/Models/MemberModels.swift
import Foundation

public struct MemberSummaryResponse: Decodable, Sendable {
    public let uye: MemberMeResponse
    public let bakiye: Int
    public let gecmis_rezervasyonlar: [BookingResponse]
}
```

```swift
// ios/SoboSociety/Theme/SoboTheme.swift
import SwiftUI

public enum SoboTheme {
    public static let ivory = Color(red: 0.97, green: 0.96, blue: 0.94) // #F7F4EF
    public static let sand = Color(red: 0.91, green: 0.88, blue: 0.84)  // #E9E1D6
    public static let line = Color(red: 0.87, green: 0.83, blue: 0.78)  // #DDD3C7
    public static let ink = Color(red: 0.17, green: 0.15, blue: 0.13)   // #2B2522
    public static let secondary = Color(red: 0.42, green: 0.36, blue: 0.32) // #6B5D52
    public static let mocha = Color(red: 0.64, green: 0.52, blue: 0.44) // #A2846F
    public static let espresso = Color(red: 0.44, green: 0.34, blue: 0.28) // #6F5647
    public static let sage = Color(red: 0.49, green: 0.55, blue: 0.45)  // #7D8B72
    public static let clay = Color(red: 0.71, green: 0.44, blue: 0.31)  // #B5714E
}
```

---

### Task 2: APIClient, KeychainManager ve AuthService

**Files:**
- Create: `ios/SoboSociety/Services/KeychainManager.swift`
- Create: `ios/SoboSociety/Services/APIClient.swift`
- Create: `ios/SoboSociety/Services/AuthService.swift`

- [ ] **Step 1: KeychainManager Güvenli Token Saklayıcısı**

```swift
// ios/SoboSociety/Services/KeychainManager.swift
import Foundation
import Security

public final class KeychainManager: @unchecked Sendable {
    public static let shared = KeychainManager()
    private let serviceName = "com.sobosociety.app"

    private init() {}

    public func save(token: String, forKey key: String) {
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    public func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    public func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **Step 2: APIClient HTTP Servis Katmanı**

```swift
// ios/SoboSociety/Services/APIClient.swift
import Foundation

public final class APIClient: Sendable {
    public static let shared = APIClient()
    public var baseURL: String = "http://185.171.25.132/api/v1"

    private init() {}

    public func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainManager.shared.get(forKey: "jwt_token") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            req.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
```

---

### Task 3: SwiftUI ViewModels ve Ekranlar (Auth, Booking, Account, Admin)

**Files:**
- Create: `ios/SoboSociety/ViewModels/AuthViewModel.swift`
- Create: `ios/SoboSociety/ViewModels/BookingViewModel.swift`
- Create: `ios/SoboSociety/Views/Auth/OTPLoginView.swift`
- Create: `ios/SoboSociety/Views/Member/BookingView.swift`
- Create: `ios/SoboSociety/Views/Member/AccountView.swift`
- Create: `ios/SoboSociety/Views/Admin/AdminTodayView.swift`
- Create: `ios/SoboSociety/Views/MainTabView.swift`

- [ ] **Step 1: AuthViewModel ve SMS OTP Giriş Ekranı**

```swift
// ios/SoboSociety/Views/Auth/OTPLoginView.swift
import SwiftUI

public struct OTPLoginView: View {
    @State private var telefon: String = ""
    @State private var kod: String = ""
    @State private var step: Int = 1
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    var onLoginSuccess: () -> Void

    public init(onLoginSuccess: @escaping () -> Void) {
        self.onLoginSuccess = onLoginSuccess
    }

    public var body: some View {
        ZStack {
            SoboTheme.ivory.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("SOBO SOCIETY")
                        .font(.custom("CormorantGaramond-Regular", size: 32))
                        .tracking(6)
                        .foregroundColor(SoboTheme.ink)
                    Text("Pilates & Barre Studio")
                        .font(.system(size: 11, weight: .light))
                        .tracking(3)
                        .foregroundColor(SoboTheme.mocha)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    if step == 1 {
                        Text("Giriş Yap / Kayıt Ol")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SoboTheme.ink)
                        TextField("5xx xxx xx xx", text: $telefon)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SoboTheme.line, lineWidth: 1))

                        Button(action: sendOTP) {
                            Text("SMS KODU GÖNDER")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(SoboTheme.espresso)
                                .cornerRadius(12)
                        }
                    } else {
                        Text("6 Haneli SMS Kodunu Girin")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SoboTheme.ink)
                        TextField("123456", text: $kod)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                        Button(action: verifyOTP) {
                            Text("GİRİŞ YAP")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(SoboTheme.espresso)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .background(SoboTheme.sand.opacity(0.4))
                .cornerRadius(18)

                Spacer()
            }
            .padding()
        }
    }

    private func sendOTP() {
        Task {
            do {
                let req = OTPSendRequest(telefon: telefon)
                let bodyData = try JSONEncoder().encode(req)
                let _: OTPSendResponse = try await APIClient.shared.request(endpoint: "/auth/otp/send", method: "POST", body: bodyData)
                await MainActor.run { step = 2 }
            } catch {
                await MainActor.run { errorMessage = "OTP Gönderilemedi" }
            }
        }
    }

    private func verifyOTP() {
        Task {
            do {
                let req = OTPVerifyRequest(telefon: telefon, kod: kod)
                let bodyData = try JSONEncoder().encode(req)
                let res: TokenResponse = try await APIClient.shared.request(endpoint: "/auth/otp/verify", method: "POST", body: bodyData)
                KeychainManager.shared.save(token: res.access_token, forKey: "jwt_token")
                await MainActor.run { onLoginSuccess() }
            } catch {
                await MainActor.run { errorMessage = "Doğrulama Başarısız" }
            }
        }
    }
}
```

---

### Task 4: Codemagic Otomasyon Pipeline (`codemagic.yaml`)

**Files:**
- Create: `ios/codemagic.yaml`

- [ ] **Step 1: Codemagic Otomatik Build Konfigürasyonu**

```yaml
# ios/codemagic.yaml
workflows:
  ios-app-store:
    name: Sobo Society iOS App Store & TestFlight Build
    instance_type: mac_mini_m1
    max_build_duration: 60
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.sobosociety.app
      vars:
        XCODE_WORKSPACE: "SoboSociety.xcworkspace"
        XCODE_SCHEME: "SoboSociety"
    scripts:
      - name: Initialize App & Dependencies
        script: |
          echo "Building Sobo Society iOS App..."
      - name: Build Xcode Archive (.ipa)
        script: |
          xcodebuild -project SoboSociety.xcodeproj \
            -scheme SoboSociety \
            -sdk iphoneos \
            -configuration Release \
            -archivePath build/SoboSociety.xcarchive \
            archive
    artifacts:
      - build/*.ipa
      - *.xcarchive
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
```

---

### Task 5: Derleme ve Bütünlük Testi

- [ ] **Step 1: iOS Kodlarının ve Yapısının Doğrulanması**
- [ ] **Step 2: Projenin `/home/sobo/ios` Dizinine Kaydedilmesi ve Git Commit Yapılması**

```bash
git add ios/
git commit -m "feat(ios): add Sobo Society SwiftUI iOS app & Codemagic pipeline"
```

---
