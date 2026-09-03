import SwiftUI
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var telefon: String = ""
    @Published public var kod: String = ""
    @Published public var step: Int = 1
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var isLoggedIn: Bool = false
    @Published public var isAdmin: Bool = false
    @Published public var currentUser: MemberMeResponse?

    public init() {
        checkToken()
    }

    public func checkToken() {
        if let token = KeychainManager.shared.get(forKey: "jwt_token"), !token.isEmpty {
            self.isLoggedIn = true
            fetchMe()
        }
    }

    public func sendOTP() async {
        guard !telefon.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Lütfen telefon numaranızı girin"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let req = OTPSendRequest(telefon: telefon)
            let bodyData = try JSONEncoder().encode(req)
            let _: OTPSendResponse = try await APIClient.shared.request(endpoint: "/auth/otp/send", method: "POST", body: bodyData)
            step = 2
        } catch {
            errorMessage = "SMS Kodu Gönderilemedi"
        }
        isLoading = false
    }

    public func verifyOTP() async {
        guard !kod.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Lütfen 6 haneli doğrulama kodunu girin"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let req = OTPVerifyRequest(telefon: telefon, kod: kod)
            let bodyData = try JSONEncoder().encode(req)
            let res: TokenResponse = try await APIClient.shared.request(endpoint: "/auth/otp/verify", method: "POST", body: bodyData)
            KeychainManager.shared.save(token: res.access_token, forKey: "jwt_token")
            isLoggedIn = true
            await fetchMe()
        } catch {
            errorMessage = "Hatalı SMS Kodu"
        }
        isLoading = false
    }

    public func fetchMe() {
        Task {
            do {
                let user: MemberMeResponse = try await APIClient.shared.request(endpoint: "/auth/me")
                self.currentUser = user
                self.isAdmin = user.is_admin ?? false
                self.registerDeviceToken()
            } catch {
                // Ignore failure if me fails
            }
        }
    }

    private func registerDeviceToken() {
        Task {
            struct DevTokenReq: Encodable {
                let device_token: String
                let platform: String
            }
            do {
                let body = try JSONEncoder().encode(DevTokenReq(device_token: "apns-ios-device-token-sync", platform: "ios"))
                let _: [String: String] = try await APIClient.shared.request(endpoint: "/my/device-token", method: "POST", body: body)
            } catch {}
        }
    }

    public func logout() {
        KeychainManager.shared.delete(forKey: "jwt_token")
        isLoggedIn = false
        isAdmin = false
        currentUser = nil
        step = 1
        telefon = ""
        kod = ""
    }
}
