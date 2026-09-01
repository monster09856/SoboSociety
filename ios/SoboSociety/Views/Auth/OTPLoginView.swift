import SwiftUI

public struct OTPLoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            SoboTheme.ivory.ignoresSafeArea()

            VStack(spacing: 32) {
                // Header Brand Logo
                VStack(spacing: 8) {
                    Text("SOBO SOCIETY")
                        .font(.custom("CormorantGaramond-Regular", size: 34))
                        .tracking(8)
                        .foregroundColor(SoboTheme.ink)

                    Text("P I L A T E S  &  B A R R E")
                        .font(.system(size: 11, weight: .light))
                        .tracking(4)
                        .foregroundColor(SoboTheme.mocha)
                }
                .padding(.top, 60)

                VStack(spacing: 24) {
                    if viewModel.step == 1 {
                        VStack(spacing: 12) {
                            Text("HOŞ GELDİNİZ")
                                .font(.system(size: 18, weight: .medium))
                                .tracking(2)
                                .foregroundColor(SoboTheme.ink)

                            Text("Telefon numaranız ile kolayca giriş yapın")
                                .font(.system(size: 13))
                                .foregroundColor(SoboTheme.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("TELEFON NUMARASI")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(SoboTheme.secondary)

                            HStack {
                                Text("+90")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SoboTheme.ink)
                                Rectangle()
                                    .fill(SoboTheme.line)
                                    .frame(width: 1, height: 20)
                                TextField("5xx xxx xx xx", text: $viewModel.telefon)
                                    .keyboardType(.phonePad)
                                    .font(.system(size: 16))
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(SoboTheme.line, lineWidth: 1)
                            )
                        }

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(SoboTheme.clay)
                        }

                        Button(action: {
                            Task { await viewModel.sendOTP() }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("SMS KODU GÖNDER")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(2)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SoboTheme.espresso)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)

                    } else {
                        VStack(spacing: 12) {
                            Text("SMS DOĞRULAMA")
                                .font(.system(size: 18, weight: .medium))
                                .tracking(2)
                                .foregroundColor(SoboTheme.ink)

                            Text("\(viewModel.telefon) numarasına gönderilen 6 haneli kodu girin")
                                .font(.system(size: 13))
                                .multilineTextAlignment(.center)
                                .foregroundColor(SoboTheme.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DOĞRULAMA KODU")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(SoboTheme.secondary)

                            TextField("123456", text: $viewModel.kod)
                                .keyboardType(.numberPad)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(SoboTheme.line, lineWidth: 1)
                                )
                        }

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(SoboTheme.clay)
                        }

                        Button(action: {
                            Task { await viewModel.verifyOTP() }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("GİRİŞ YAP")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(2)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SoboTheme.espresso)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)

                        Button(action: {
                            viewModel.step = 1
                        }) {
                            Text("Telefon Numarasını Değiştir")
                                .font(.system(size: 13))
                                .foregroundColor(SoboTheme.secondary)
                                .underline()
                        }
                    }
                }
                .padding(28)
                .background(SoboTheme.sand.opacity(0.35))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(SoboTheme.line.opacity(0.6), lineWidth: 1)
                )

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
