import SwiftUI
import Combine

@MainActor
public final class BookingViewModel: ObservableObject {
    @Published public var sessions: [ClassSessionDTO] = []
    @Published public var memberSummary: MemberSummaryResponse?
    @Published public var selectedDateIndex: Int = 0
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var successMessage: String?

    public var selectedDateString: String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: selectedDateIndex, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    public init() {}

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        await fetchSummary()
        await fetchSessions()
        isLoading = false
    }

    public func fetchSummary() async {
        do {
            let summary: MemberSummaryResponse = try await APIClient.shared.request(endpoint: "/my/summary")
            self.memberSummary = summary
        } catch {
            print("Failed to fetch summary: \(error)")
        }
    }

    public func fetchSessions() async {
        do {
            let res: [ClassSessionDTO] = try await APIClient.shared.request(endpoint: "/sessions")
            self.sessions = res
        } catch {
            self.errorMessage = "Ders oturumları yüklenemedi."
        }
    }

    public func bookSession(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let req = BookingCreateRequest(session_id: id)
            let bodyData = try JSONEncoder().encode(req)
            let _: BookingResponse = try await APIClient.shared.request(endpoint: "/bookings", method: "POST", body: bodyData)
            successMessage = "Rezervasyonunuz başarıyla oluşturuldu!"
            await loadData()
        } catch {
            errorMessage = "Rezervasyon oluşturulamadı (Bakiye yetersiz veya kontenjan dolu olabilir)."
        }
        isLoading = false
    }

    public func cancelBooking(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let _: BookingResponse = try await APIClient.shared.request(endpoint: "/bookings/\(id)/cancel", method: "POST")
            successMessage = "Rezervasyon iptal edildi."
            await loadData()
        } catch {
            errorMessage = "Rezervasyon iptal edilemedi."
        }
        isLoading = false
    }

    public func joinWaitlist(sessionId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let req = WaitlistCreateRequest(session_id: sessionId)
            let bodyData = try JSONEncoder().encode(req)
            let _: WaitlistResponse = try await APIClient.shared.request(endpoint: "/bookings/waitlist", method: "POST", body: bodyData)
            successMessage = "Bekleme sırasına alındınız!"
            await loadData()
        } catch {
            errorMessage = "Bekleme sırasına girilemedi."
        }
        isLoading = false
    }
}
