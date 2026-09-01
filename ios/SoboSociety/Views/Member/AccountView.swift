import SwiftUI

public struct AccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var summary: MemberSummaryResponse?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

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

                            // Credit Badge
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
                                .foregroundColor(SoboTheme.clay)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(SoboTheme.clay.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Hesabım")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SoboTheme.ivory, for: .navigationBar)
            .onAppear {
                fetchSummary()
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

struct AttendanceRecordRow: View {
    let booking: BookingResponse

    var statusColor: Color {
        switch booking.durum.lowercased() {
        case "attended", "katildi", "booked", "rezerve":
            return SoboTheme.sage // Sage Green
        case "no_show", "gelmedi":
            return SoboTheme.clay // Clay Red
        default:
            return SoboTheme.secondary
        }
    }

    var statusTitle: String {
        switch booking.durum.lowercased() {
        case "attended", "katildi":
            return "Katıldı"
        case "no_show", "gelmedi":
            return "Gelmedi"
        case "booked", "rezerve":
            return "Rezerve"
        case "cancelled", "iptal":
            return "İptal Edildi"
        default:
            return booking.durum
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.session?.resolvedClassType.ad ?? "Stüdyo Dersi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SoboTheme.ink)

                Text(booking.session?.startFormatted ?? booking.olusturuldu_utc ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(SoboTheme.secondary)
            }

            Spacer()

            // Status Badge (attended -> Sage green, no_show -> Clay red)
            Text(statusTitle)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor)
                .cornerRadius(12)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SoboTheme.line, lineWidth: 1)
        )
    }
}
