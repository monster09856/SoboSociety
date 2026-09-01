import SwiftUI

public struct BookingView: View {
    @ObservedObject var viewModel: BookingViewModel
    @State private var days: [(dayName: String, dayNum: String, index: Int)] = []

    public init(viewModel: BookingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                SoboTheme.ivory.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Balance Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DERS BAKİYESİ")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(SoboTheme.secondary)

                            Text("\(viewModel.memberSummary?.bakiye ?? 0) Kredi")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(SoboTheme.ink)
                        }

                        Spacer()

                        Image(systemName: "ticket.fill")
                            .font(.system(size: 28))
                            .foregroundColor(SoboTheme.mocha)
                    }
                    .padding(20)
                    .background(SoboTheme.sand.opacity(0.5))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(SoboTheme.line, lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Day Selection Strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(days, id: \.index) { day in
                                Button(action: {
                                    viewModel.selectedDateIndex = day.index
                                    Task { await viewModel.fetchSessions() }
                                }) {
                                    VStack(spacing: 6) {
                                        Text(day.dayName.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(1)
                                        Text(day.dayNum)
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .frame(width: 58, height: 68)
                                    .background(viewModel.selectedDateIndex == day.index ? SoboTheme.espresso : Color.white)
                                    .foregroundColor(viewModel.selectedDateIndex == day.index ? .white : SoboTheme.ink)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(viewModel.selectedDateIndex == day.index ? SoboTheme.espresso : SoboTheme.line, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Success / Error Banners
                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SoboTheme.sage)
                            .padding(.horizontal)
                    }
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SoboTheme.clay)
                            .padding(.horizontal)
                    }

                    // Live Class Sessions List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(SoboTheme.espresso)
                        Spacer()
                    } else if viewModel.sessions.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundColor(SoboTheme.mocha)
                            Text("Bu tarih için yayınlanmış ders bulunmuyor.")
                                .font(.system(size: 14))
                                .foregroundColor(SoboTheme.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.sessions) { session in
                                    ClassSessionCardView(session: session, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Ders Programı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SoboTheme.ivory, for: .navigationBar)
            .onAppear {
                generateDays()
                Task { await viewModel.loadData() }
            }
        }
    }

    private func generateDays() {
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")

        var result: [(dayName: String, dayNum: String, index: Int)] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                formatter.dateFormat = "EEE"
                let dName = i == 0 ? "Bugün" : formatter.string(from: date)
                formatter.dateFormat = "dd"
                let dNum = formatter.string(from: date)
                result.append((dayName: dName, dayNum: dNum, index: i))
            }
        }
        self.days = result
    }
}

struct ClassSessionCardView: View {
    let session: ClassSessionDTO
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.resolvedClassType.ad.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1)
                        .foregroundColor(SoboTheme.ink)

                    Text("Eğitmen: \(session.resolvedInstructor.ad)")
                        .font(.system(size: 13))
                        .foregroundColor(SoboTheme.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.startFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SoboTheme.espresso)

                    Text("\(session.resolvedClassType.sure_dk ?? 50) Dk")
                        .font(.system(size: 11))
                        .foregroundColor(SoboTheme.secondary)
                }
            }

            Divider()
                .overlay(SoboTheme.line)

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SoboTheme.mocha)
                    Text("Kontenjan: \(session.resolvedDoluSayi)/\(session.resolvedKontenjan)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SoboTheme.ink)

                    if session.kalanYer > 0 {
                        Text("(\(session.kalanYer) yer kaldi)")
                            .font(.system(size: 11))
                            .foregroundColor(SoboTheme.sage)
                    } else {
                        Text("(Dolu)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(SoboTheme.clay)
                    }
                }

                Spacer()

                // Action Buttons: Rezerve Et / İptal Et / Bekleme Sırası
                if session.uye_rezervasyonu_var == true {
                    Button(action: {
                        Task { await viewModel.cancelBooking(id: session.id) }
                    }) {
                        Text("İptal Et")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SoboTheme.clay)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else if session.kalanYer > 0 {
                    Button(action: {
                        Task { await viewModel.bookSession(id: session.id) }
                    }) {
                        Text("Rezerve Et")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SoboTheme.espresso)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        Task { await viewModel.joinWaitlist(sessionId: session.id) }
                    }) {
                        Text("Bekleme Sırası")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SoboTheme.sage)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SoboTheme.line, lineWidth: 1)
        )
    }
}
