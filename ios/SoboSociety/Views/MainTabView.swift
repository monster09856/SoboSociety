import SwiftUI

public struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var bookingViewModel = BookingViewModel()
    @State private var selectedTab: Int = 0

    public init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            BookingView(viewModel: bookingViewModel)
                .tabItem {
                    Label("Program", systemImage: "calendar")
                }
                .tag(0)

            AccountView(authViewModel: authViewModel)
                .tabItem {
                    Label("Hesabım", systemImage: "person.crop.circle")
                }
                .tag(1)

            if authViewModel.isAdmin {
                AdminTodayView()
                    .tabItem {
                        Label("Eğitmen Paneli", systemImage: "list.clipboard")
                    }
                    .tag(2)
            }
        }
        .tint(SoboTheme.espresso)
    }
}
