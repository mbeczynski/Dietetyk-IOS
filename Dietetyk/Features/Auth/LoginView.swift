import SwiftUI
import UIKit

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.stage {
                case .credentials:
                    credentialsForm
                case .twoFactorCode:
                    twoFactorCodeForm
                case .twoFactorSetup(_, let qrCode, let secret):
                    twoFactorSetupForm(qrCode: qrCode, secret: secret)
                case .forcedPasswordChange:
                    passwordChangeForm
                }
            }
            .navigationTitle("Dietetyk AI")
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Logowanie

    private var credentialsForm: some View {
        Form {
            Section {
                TextField("Nazwa użytkownika", text: $viewModel.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Hasło", text: $viewModel.password)
                    .textContentType(.password)
            }

            errorSection

            Section {
                Button {
                    Task { await viewModel.submitCredentials() }
                } label: {
                    submitLabel("Zaloguj się")
                }
                .disabled(!viewModel.canSubmitCredentials || viewModel.isLoading)
            }
        }
    }

    // MARK: - 2FA: wpisanie kodu (logowanie do istniejącego konta z 2FA)

    private var twoFactorCodeForm: some View {
        Form {
            Section {
                Text("Weryfikacja dwuetapowa")
                    .font(.headline)
                Text("Wpisz kod z aplikacji uwierzytelniającej (np. Google Authenticator).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("Kod 6-cyfrowy", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
            }

            errorSection

            Section {
                Button {
                    Task { await viewModel.submitTwoFactorCode() }
                } label: {
                    submitLabel("Potwierdź")
                }
                .disabled(viewModel.code.isEmpty || viewModel.isLoading)

                Button("Wróć do logowania", role: .cancel) {
                    viewModel.cancelTwoStepFlow()
                }
            }
        }
    }

    // MARK: - 2FA: pierwsza konfiguracja (QR + sekret)

    private func twoFactorSetupForm(qrCode: String, secret: String) -> some View {
        Form {
            Section {
                Text("Skonfiguruj weryfikację dwuetapową")
                    .font(.headline)
                Text("Zeskanuj kod QR w aplikacji uwierzytelniającej, a potem wpisz wygenerowany kod, aby ją włączyć.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                qrCodeImage(from: qrCode)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                LabeledContent("Klucz (jeśli nie możesz zeskanować)") {
                    Text(secret)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Section {
                TextField("Kod 6-cyfrowy", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
            }

            errorSection

            Section {
                Button {
                    Task { await viewModel.confirmTwoFactorSetup() }
                } label: {
                    submitLabel("Potwierdź i włącz 2FA")
                }
                .disabled(viewModel.code.isEmpty || viewModel.isLoading)

                Button("Wróć do logowania", role: .cancel) {
                    viewModel.cancelTwoStepFlow()
                }
            }
        }
    }

    // MARK: - Wymuszona zmiana hasła

    private var passwordChangeForm: some View {
        Form {
            Section {
                Text("Wymagana zmiana hasła")
                    .font(.headline)
                Text("Administrator wymaga ustawienia nowego hasła przed dalszym korzystaniem z konta.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                SecureField("Nowe hasło", text: $viewModel.newPassword)
                    .textContentType(.newPassword)
                SecureField("Powtórz nowe hasło", text: $viewModel.newPasswordConfirm)
                    .textContentType(.newPassword)
            }

            errorSection

            Section {
                Button {
                    Task { await viewModel.submitNewPassword() }
                } label: {
                    submitLabel("Zmień hasło")
                }
                .disabled(viewModel.isLoading)

                Button("Wróć do logowania", role: .cancel) {
                    viewModel.cancelTwoStepFlow()
                }
            }
        }
    }

    // MARK: - Wspólne elementy

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Section {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func submitLabel(_ title: String) -> some View {
        HStack {
            Spacer()
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(title)
            }
            Spacer()
        }
    }

    /// `qrCode` z backendu to data URL PNG base64
    /// (`data:image/png;base64,...`, generowany biblioteką `qrcode` w
    /// `backend/routes/auth.js`).
    @ViewBuilder
    private func qrCodeImage(from dataURL: String) -> some View {
        if let commaIndex = dataURL.firstIndex(of: ","),
           let data = Data(base64Encoded: String(dataURL[dataURL.index(after: commaIndex)...])),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        } else {
            Text("Nie udało się wyświetlić kodu QR. Użyj klucza tekstowego poniżej.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
