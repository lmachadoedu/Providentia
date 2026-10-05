import SwiftUI
import PhotosUI

struct RootView: View {
    @AppStorage("didOnboard") private var didOnboard = false
    var body: some View {
        if didOnboard { HomeView() } else { OnboardingView() }
    }
}

struct OnboardingView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage("profileImage") private var profileImage = Data()
    @AppStorage("appearance") private var appearance = "system"

    @State private var name = ""
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 70)

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.green.gradient)
                        .frame(width: 92, height: 92)
                    Image(systemName: "wallet.bifold.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 7) {
                    Text("Providentia").font(.largeTitle.bold())
                    Text("Suas contas com ordem e tranquilidade.")
                        .foregroundStyle(.secondary)
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    profileAvatar(size: 92)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .padding(8)
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Como podemos te chamar?").font(.subheadline.bold())
                    TextField("Seu nome", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Aparência").font(.subheadline.bold())
                    Picker("Aparência", selection: $appearance) {
                        Text("Automático").tag("system")
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                    }.pickerStyle(.segmented)
                }

                Button {
                    userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    didOnboard = !userName.isEmpty
                } label: {
                    Text("Começar")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer(minLength: 30)
            }
            .padding(28)
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    profileImage = data
                }
            }
        }
    }

    @ViewBuilder
    private func profileAvatar(size: CGFloat) -> some View {
        if let ui = UIImage(data: profileImage) {
            Image(uiImage: ui).resizable().scaledToFill()
                .frame(width: size, height: size).clipShape(Circle())
        } else {
            Circle().fill(.green.opacity(0.14))
                .frame(width: size, height: size)
                .overlay(Image(systemName: "person.fill").font(.title).foregroundStyle(.green))
        }
    }
}
