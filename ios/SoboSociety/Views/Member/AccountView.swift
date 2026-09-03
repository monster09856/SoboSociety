import SwiftUI

public struct AccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var summary: MemberSummaryResponse?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showDeleteAccountAlert: Bool = false
    @State private var isSavingMeasurements: Bool = false

    // Measurement States
    @State private var bel: String = ""
    @State private var kalca: String = ""
    @State private var sagIcBacak: String = ""
    @State private var sagBacak: String = ""
    @State private var solIcBacak: String = ""
    @State private var solBacak: String = ""
    @State private var sagKol: String = ""
    @State private var solKol: String = ""
    @State private var boy: String = ""
    @State private var kilo: String = ""
    @State private var saglikNotu: String = ""
    @State private var saveSuccessMsg: String?

    public init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                SoboTheme.ivory.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header Card
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(SoboTheme.sand)
                                    .frame(width: 72, height: 72)
                                Text(summary?.displayAd.prefix(1).uppercased() ?? "S")
                                    .font(.custom("CormorantGaramond-Regular", size: 36))
                                    .foregroundColor(SoboTheme.espresso)
                            }

                            VStack(spacing: 4) {
                                Text(summary?.displayAd ?? authViewModel.currentUser?.displayName ?? "Üye Profil")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(SoboTheme.ink)

                                Text(summary?.displayTelefon ?? authViewModel.currentUser?.telefon ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(SoboTheme.secondary)
                            }

                            // Credit Badge & Admin Badge
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundColor(SoboTheme.espresso)
                                    Text("Kalan Ders Kredisi: \(summary?.bakiye ?? 0)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(SoboTheme.espresso)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(SoboTheme.sand.opacity(0.6))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(SoboTheme.line, lineWidth: 1)
                                )

                                if authViewModel.isAdmin {
                                    HStack(spacing: 4) {
                                        Image(systemName: "shield.checkmark.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white)
                                        Text("Admin / Yönetici")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(SoboTheme.espresso)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SoboTheme.line, lineWidth: 1)
                        )

                        // Vücut Ölçülerim & Form Bilgilerim Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "ruler.fill")
                                    .foregroundColor(SoboTheme.mocha)
                                Text("VÜCUT ÖLÇÜLERİM & FORM BİLGİLERİM")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(SoboTheme.espresso)
                            }

                            if let msg = saveSuccessMsg {
                                Text(msg)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SoboTheme.sage)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(SoboTheme.sage.opacity(0.15))
                                    .cornerRadius(10)
                            }

                            HStack(spacing: 10) {
                                measurementField(label: "Bel", value: $bel)
                                measurementField(label: "Kalça", value: $kalca)
                            }
                            HStack(spacing: 10) {
                                measurementField(label: "Sağ İç Bacak", value: $sagIcBacak)
                                measurementField(label: "Sağ Bacak", value: $sagBacak)
                            }
                            HStack(spacing: 10) {
                                measurementField(label: "Sol İç Bacak", value: $solIcBacak)
                                measurementField(label: "Sol Bacak", value: $solBacak)
                            }
                            HStack(spacing: 10) {
                                measurementField(label: "Sağ Kol", value: $sagKol)
                                measurementField(label: "Sol Kol", value: $solKol)
                            }
                            HStack(spacing: 10) {
                                measurementField(label: "Boy (cm)", value: $boy)
                                measurementField(label: "Kilo (kg)", value: $kilo)
                            }
                            measurementField(label: "Sağlık & Hedef Notum", value: $saglikNotu, placeholder: "Varsa sakatlık veya hedefiniz...")

                            Button(action: saveMeasurements) {
                                Group {
                                    if isSavingMeasurements {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("ÖLÇÜLERİMİ VE FORMUMU KAYDET")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SoboTheme.espresso)
                                .cornerRadius(12)
                            }
                            .disabled(isSavingMeasurements)
                        }
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SoboTheme.line, lineWidth: 1)
                        )

                        // Stüdyo & Paket Kullanım Kuralları Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(SoboTheme.mocha)
                                Text("PAKET KULLANIM & DERS KURALLARI")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(SoboTheme.secondary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Sınıf Kontenjanı: Maksimum 5 Üye")
                                Text("• İptal Kuralı: Derse en az 12 saat kala iptal edilebilir")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(SoboTheme.espresso)
                                Text("• Paket Süreleri: 4 Ders (4 Hafta), 8 Ders (6 Hafta), 12 Ders (8 Hafta)")
                                Text("• Ders Süresi: 45 - 50 Dakika")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SoboTheme.ink)
                            .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SoboTheme.sand.opacity(0.4))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(SoboTheme.line, lineWidth: 1)
                        )

                        // Past Class Attendance Records Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DERS GEÇMİŞİ VE KATILIM")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(SoboTheme.secondary)

                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(SoboTheme.espresso)
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            } else if let records = summary?.gecmis_rezervasyonlar, !records.isEmpty {
                                VStack(spacing: 10) {
                                    ForEach(records) { booking in
                                        AttendanceRecordRow(booking: booking)
                                    }
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 6) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 28))
                                            .foregroundColor(SoboTheme.mocha)
                                        Text("Henüz geçmiş ders kaydı bulunmuyor.")
                                            .font(.system(size: 13))
                                            .foregroundColor(SoboTheme.secondary)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(SoboTheme.line, lineWidth: 1)
                                )
                            }
                        }

                        // App & System Actions
                        VStack(spacing: 12) {
                            Button(action: {
                                authViewModel.logout()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("ÇIKIŞ YAP")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(1.5)
                                }
                                .foregroundColor(SoboTheme.espresso)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(SoboTheme.line, lineWidth: 1)
                                )
                            }

                            Button(action: {
                                showDeleteAccountAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("HESABIMI VE VERİLERİMİ SİL")
                                        .font(.system(size: 12, weight: .bold))
                                        .tracking(1.2)
                                }
                                .foregroundColor(SoboTheme.clay)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SoboTheme.clay.opacity(0.08))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(SoboTheme.clay.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .alert("Hesabınızı Silmek İstediğinize Emin Misiniz?", isPresented: $showDeleteAccountAlert) {
                Button("İptal", role: .cancel) { }
                Button("Evet, Hesabımı Sil", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Hesabınız ve tüm kayıtlı ders geçmişiniz kalıcı olarak silinecektir. Bu işlem geri alınamaz.")
            }
            .navigationTitle("Hesabım")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SoboTheme.ivory, for: .navigationBar)
            .onAppear {
                fetchSummary()
                fetchMe()
            }
        }
    }

    private func measurementField(label: String, value: Binding<String>, placeholder: String = "cm / kg") -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(SoboTheme.secondary)
            TextField(placeholder, text: value)
                .font(.system(size: 12, weight: .semibold))
                .padding(10)
                .background(SoboTheme.sand.opacity(0.3))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SoboTheme.line, lineWidth: 1))
        }
    }

    private func fetchMe() {
        Task {
            struct MemberMeRes: Decodable {
                let bel: String?
                let kalca: String?
                let sag_ic_bacak: String?
                let sag_bacak: String?
                let sol_ic_bacak: String?
                let sol_bacak: String?
                let sag_kol: String?
                let sol_kol: String?
                let boy: String?
                let kilo: String?
                let saglik_notu: String?
            }
            do {
                let meData: MemberMeRes = try await APIClient.shared.request(endpoint: "/auth/me")
                await MainActor.run {
                    self.bel = meData.bel ?? ""
                    self.kalca = meData.kalca ?? ""
                    self.sagIcBacak = meData.sag_ic_bacak ?? ""
                    self.sagBacak = meData.sag_bacak ?? ""
                    self.solIcBacak = meData.sol_ic_bacak ?? ""
                    self.solBacak = meData.sol_bacak ?? ""
                    self.sagKol = meData.sag_kol ?? ""
                    self.solKol = meData.sol_kol ?? ""
                    self.boy = meData.boy ?? ""
                    self.kilo = meData.kilo ?? ""
                    self.saglikNotu = meData.saglik_notu ?? ""
                }
            } catch {}
        }
    }

    private func saveMeasurements() {
        isSavingMeasurements = true
        saveSuccessMsg = nil
        Task {
            struct UpdateReq: Encodable {
                let bel: String
                let kalca: String
                let sag_ic_bacak: String
                let sag_bacak: String
                let sol_ic_bacak: String
                let sol_bacak: String
                let sag_kol: String
                let sol_kol: String
                let boy: String
                let kilo: String
                let saglik_notu: String
            }
            do {
                let body = UpdateReq(
                    bel: bel, kalca: kalca, sag_ic_bacak: sagIcBacak, sag_bacak: sagBacak,
                    sol_ic_bacak: solIcBacak, sol_bacak: solBacak, sag_kol: sagKol, sol_kol: solKol,
                    boy: boy, kilo: kilo, saglik_notu: saglikNotu
                )
                let enc = try JSONEncoder().encode(body)
                let _: [String: String] = try await APIClient.shared.request(endpoint: "/auth/me", method: "PUT", body: enc)
                await MainActor.run {
                    self.isSavingMeasurements = false
                    self.saveSuccessMsg = "Vücut ölçüleriniz kaydedildi! ✨"
                }
            } catch {
                await MainActor.run {
                    self.isSavingMeasurements = false
                }
            }
        }
    }

    private func fetchSummary() {
        isLoading = true
        Task {
            do {
                let res: MemberSummaryResponse = try await APIClient.shared.request(endpoint: "/my/summary")
                await MainActor.run {
                    self.summary = res
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

public struct AttendanceRecordRow: View {
    public let booking: BookingResponse

    public init(booking: BookingResponse) {
        self.booking = booking
    }

    private var statusColor: Color {
        switch booking.durum {
        case "attended":
            return SoboTheme.sage
        case "no_show":
            return SoboTheme.clay
        case "booked":
            return SoboTheme.espresso
        default:
            return SoboTheme.secondary
        }
    }

    private var statusTitle: String {
        switch booking.durum {
        case "attended":
            return "Katıldı"
        case "no_show":
            return "Gelmedi"
        case "booked":
            return "Rezerve"
        case "cancelled":
            return "İptal Edildi"
        default:
            return booking.durum.capitalized
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.session?.ders_adi ?? "Ders Oturumu")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SoboTheme.ink)
                if let baslangic = booking.session?.baslangic_utc {
                    Text(baslangic)
                        .font(.system(size: 11))
                        .foregroundColor(SoboTheme.secondary)
                }
            }
            Spacer()
            Text(statusTitle)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SoboTheme.line, lineWidth: 1)
        )
    }
}
