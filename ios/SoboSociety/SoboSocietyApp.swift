import SwiftUI

@main
struct SoboSocietyApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    MainTabView(authViewModel: authViewModel)
                } else {
                    OTPLoginView(viewModel: authViewModel)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
