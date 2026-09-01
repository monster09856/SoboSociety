import SwiftUI

public struct AdminTodayView: View {
    @State private var sessions: [TodaySessionResponse] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // 5 Saniyelik DM Hızlı Kayıt Sheet state
    @State private var showQuickBookingSheet: Bool = false
    @State private var targetSessionId: Int? = nil
    @State private var dmPhone: String = ""
    @State private var dmName: String = ""
    @State private var isSubmittingDM: Bool = false

    // Yoklama state: session_id -> Set of member_ids present
    @State private var attendanceMap: [Int: Set<Int>] = [:]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                SoboTheme.ivory.ignoresSafeArea()

                VStack(spacing: 16) {
                    if let succ = successMessage {
                        Text(succ)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SoboTheme.sage)
                            .padding(.horizontal)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SoboTheme.clay)
                            .padding(.horizontal)
                    }

                    if isLoading {
                        Spacer()
                        ProgressView("Bugünün dersleri yükleniyor...")
                            .tint(SoboTheme.espresso)
                        Spacer()
                    } else if sessions.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 40))
                                .foregroundColor(SoboTheme.mocha)
                            Text("Bugün için tanımlanmış ders oturumu bulunmuyor.")
                                .font(.system(size: 14))
                                .foregroundColor(SoboTheme.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 18) {
                                ForEach(sessions) { session in
                                    AdminSessionCardView(
                                        session: session,
                                        attendanceSet: Binding(
                                            get: { attendanceMap[session.id] ?? defaultAttendanceSet(for: session) },
                                            set: { attendanceMap[session.id] = $0 }
                                        ),
                                        onQuickBookingClick: {
                                            targetSessionId = session.id
                                            showQuickBookingSheet = true
                                        },
                                        onSubmitAttendance: {
                                            submitAttendance(sessionId: session.id)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Eğitmen Yoklama & DM Kayıt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SoboTheme.ivory, for: .navigationBar)
            .sheet(isPresented: $showQuickBookingSheet) {
                QuickBookingSheet(
                    sessionId: targetSessionId ?? 0,
                    phone: $dmPhone,
                    name: $dmName,
                    isSubmitting: $isSubmittingDM,
                    onSubmit: performQuickBooking
                )
            }
            .onAppear {
                fetchTodaySessions()
            }
        }
    }

    private func defaultAttendanceSet(for session: TodaySessionResponse) -> Set<Int> {
        let attendedMemberIds = session.resolvedAttendees
            .filter { $0.durum.lowercased() == "attended" || $0.durum.lowercased() == "katildi" }
            .map { $0.member_id }
        return Set(attendedMemberIds)
    }

    private func fetchTodaySessions() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let res: [TodaySessionResponse] = try await APIClient.shared.request(endpoint: "/admin/today")
                await MainActor.run {
                    self.sessions = res
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Eğitmen paneli verileri yüklenemedi."
                    self.isLoading = false
                }
            }
        }
    }

    private func performQuickBooking() {
        guard let sId = targetSessionId, !dmPhone.isEmpty else { return }
        isSubmittingDM = true
        Task {
            do {
                let req = QuickBookingRequest(telefon: dmPhone, session_id: sId, ad: dmName.isEmpty ? nil : dmName)
                let bodyData = try JSONEncoder().encode(req)
                let _: BookingResponse = try await APIClient.shared.request(endpoint: "/admin/quick-booking", method: "POST", body: bodyData)
                await MainActor.run {
                    isSubmittingDM = false
                    showQuickBookingSheet = false
                    dmPhone = ""
                    dmName = ""
                    successMessage = "DM üyesi 5 saniyede başarıyla derse kaydedildi!"
                    fetchTodaySessions()
                }
            } catch {
                await MainActor.run {
                    isSubmittingDM = false
                    errorMessage = "DM kaydı yapılamadı."
                }
            }
        }
    }

    private func submitAttendance(sessionId: Int) {
        let presentSet = attendanceMap[sessionId] ?? []
        Task {
            do {
                let req = AttendanceSubmitRequest(session_id: sessionId, gelen_member_ids: Array(presentSet))
                let bodyData = try JSONEncoder().encode(req)
                let res: AttendanceSubmitResponse = try await APIClient.shared.request(endpoint: "/admin/attendance", method: "POST", body: bodyData)
                await MainActor.run {
                    successMessage = "Yoklama kaydedildi! (\(res.gelen) katıldı, \(res.gelmeyen) gelmedi)"
                    fetchTodaySessions()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Yoklama kaydedilemedi."
                }
            }
        }
    }
}

struct AdminSessionCardView: View {
    let session: TodaySessionResponse
    @Binding var attendanceSet: Set<Int>
    var onQuickBookingClick: () -> Void
    var onSubmitAttendance: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.class_type?.ad.uppercased() ?? "REFORMER PILATES")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(1)
                        .foregroundColor(SoboTheme.ink)

                    Text("Eğitmen: \(session.instructor?.ad ?? "Eğitmen") • Saat: \(session.startFormatted)")
                        .font(.system(size: 13))
                        .foregroundColor(SoboTheme.secondary)
                }

                Spacer()

                // DM 5-sec Quick Booking Button
                Button(action: onQuickBookingClick) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                        Text("+ DM Hızlı Kayıt")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(SoboTheme.espresso)
                    .cornerRadius(8)
                }
            }

            Divider()
                .overlay(SoboTheme.line)

            // Katılımcı Listesi ve Yoklama Butonları
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("KATILIMCI YOKLAMASI (\(session.resolvedAttendees.count)/\(session.kontenjan))")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundColor(SoboTheme.secondary)

                    Spacer()
                }

                if session.resolvedAttendees.isEmpty {
                    Text("Henüz derse kayıtlı üye bulunmuyor.")
                        .font(.system(size: 12))
                        .foregroundColor(SoboTheme.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(session.resolvedAttendees) { attendee in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attendee.ad)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SoboTheme.ink)
                                Text(attendee.telefon)
                                    .font(.system(size: 11))
                                    .foregroundColor(SoboTheme.secondary)
                            }

                            Spacer()

                            // Yoklama Düğmeleri (Katıldı / Gelmedi)
                            HStack(spacing: 8) {
                                Button(action: {
                                    attendanceSet.insert(attendee.member_id)
                                }) {
                                    Text("Katıldı")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(attendanceSet.contains(attendee.member_id) ? SoboTheme.sage : SoboTheme.sand.opacity(0.5))
                                        .foregroundColor(attendanceSet.contains(attendee.member_id) ? .white : SoboTheme.ink)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    attendanceSet.remove(attendee.member_id)
                                }) {
                                    Text("Gelmedi")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(!attendanceSet.contains(attendee.member_id) ? SoboTheme.clay : SoboTheme.sand.opacity(0.5))
                                        .foregroundColor(!attendanceSet.contains(attendee.member_id) ? .white : SoboTheme.ink)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(10)
                        .background(SoboTheme.sand.opacity(0.2))
                        .cornerRadius(10)
                    }

                    // Yoklamayı Kaydet Button
                    Button(action: onSubmitAttendance) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("YOKLAMAYI KAYDET")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(SoboTheme.sage)
                        .cornerRadius(10)
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SoboTheme.line, lineWidth: 1)
        )
    }
}

struct QuickBookingSheet: View {
    let sessionId: Int
    @Binding var phone: String
    @Binding var name: String
    @Binding var isSubmitting: Bool
    var onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SoboTheme.ivory.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("5 Saniyelik DM Hızlı Kayıt")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(SoboTheme.ink)
                        Text("Instagram DM'den yazan üyenin numarasını girin")
                            .font(.system(size: 13))
                            .foregroundColor(SoboTheme.secondary)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TELEFON NUMARASI *")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(SoboTheme.secondary)
                            TextField("5xx xxx xx xx", text: $phone)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SoboTheme.line, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("AD SOYAD (OPSİYONEL)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(SoboTheme.secondary)
                            TextField("Ayşe Yılmaz", text: $name)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SoboTheme.line, lineWidth: 1))
                        }
                    }

                    Spacer()

                    Button(action: onSubmit) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "bolt.fill")
                                Text("ÜYEYİ DERSE KAYDET")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(1)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SoboTheme.espresso)
                        .cornerRadius(12)
                    }
                    .disabled(phone.isEmpty || isSubmitting)
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(SoboTheme.secondary)
                }
            }
        }
    }
}
