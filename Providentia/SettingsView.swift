import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @AppStorage("userName") private var userName = ""
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("profileImage") private var profileImage = Data()

    @State private var selectedItem: PhotosPickerItem?
    @State private var exporting = false
    @State private var importing = false
    @State private var backupDocument = BackupDocument()
    @State private var message = ""

    var body: some View {
        Form {
            Section("Meu perfil") {
                HStack(spacing: 14) {
                    avatar
                    PhotosPicker("Trocar foto", selection: $selectedItem, matching: .images)
                }
                TextField("Nome", text: $userName)
            }

            Section("Aparência") {
                Picker("Tema", selection: $appearance) {
                    Text("Automático").tag("system")
                    Text("Claro").tag("light")
                    Text("Escuro").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section {
    Button {
        backupDocument = BackupDocument(data: store.backupData() ?? Data())
        exporting = true
    } label: {
        Label("Exportar backup", systemImage: "square.and.arrow.up")
    }

    Button {
        importing = true
    } label: {
        Label("Restaurar backup", systemImage: "square.and.arrow.down")
    }

    if !message.isEmpty {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
} header: {
    Text("Backup")
} footer: {
    Text("Guarde o arquivo de backup no app Arquivos ou em outro local seguro.")
}

            Section("Providentia") {
                LabeledContent("Versão", value: "1.0")
                Text("“A confiança na Providência Divina é a fé firme e viva de que Deus nos pode ajudar e nos ajudará.”")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
        .onChange(of: selectedItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    profileImage = data
                }
            }
        }
        .fileExporter(
            isPresented: $exporting,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "Providentia-Backup"
        ) { result in
            message = result.isSuccess ? "Backup exportado com sucesso." : "Não foi possível exportar o backup."
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                try store.restore(from: data)
                message = "Backup restaurado com sucesso."
            } catch {
                message = "Não foi possível restaurar esse arquivo."
            }
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let ui = UIImage(data: profileImage) {
            Image(uiImage: ui).resizable().scaledToFill()
                .frame(width: 62, height: 62).clipShape(Circle())
        } else {
            Circle().fill(.green.opacity(0.15)).frame(width: 62, height: 62)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.green))
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data = Data()

    init() {}
    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
