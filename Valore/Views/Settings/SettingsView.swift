import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]

    @State private var editingWallet: Wallet?
    @State private var showingNewWallet = false
    @State private var exportDocument: BackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingRestore: BackupFile?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(wallets) { wallet in
                        Button { editingWallet = wallet } label: {
                            HStack {
                                Label {
                                    Text(wallet.name)
                                        .foregroundStyle(Color.primary)
                                } icon: {
                                    Image(systemName: wallet.symbol)
                                }
                                Spacer()
                                Text(Fmt.rupiah(wallet.balance))
                                    .foregroundStyle(Color.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    Button { showingNewWallet = true } label: {
                        Label("Tambah dompet", systemImage: "plus")
                    }
                } header: {
                    Text("Dompet")
                } footer: {
                    Text("Saldo dompet = saldo awal + pemasukan − pengeluaran.")
                }

                Section {
                    // Exporter & importer ditempel di view berbeda: dua-duanya di satu view bikin salah satu tidak jalan.
                    Button(action: prepareExport) {
                        Label("Ekspor cadangan (JSON)", systemImage: "square.and.arrow.up")
                    }
                    .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .json, defaultFilename: backupFilename) { result in
                        if case .failure(let error) = result { message = "Gagal ekspor: \(error.localizedDescription)" }
                    }

                    Button { showingImporter = true } label: {
                        Label("Pulihkan dari cadangan", systemImage: "square.and.arrow.down")
                    }
                    .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], onCompletion: loadBackup)
                } header: {
                    Text("Cadangan data")
                } footer: {
                    Text("Semua data cuma tersimpan di iPhone ini. Ekspor berkala ke Files atau iCloud Drive supaya aman kalau HP hilang atau app terhapus.")
                }

                Section {
                    LabeledContent("Versi", value: appVersion)
                }
            }
            .navigationTitle("Pengaturan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Selesai") { dismiss() }
                }
            }
            .sheet(item: $editingWallet) { wallet in
                WalletFormView(wallet: wallet, canDelete: wallets.count > 1)
            }
            .sheet(isPresented: $showingNewWallet) { WalletFormView() }
            .confirmationDialog(
                "Ganti semua data dengan isi cadangan?",
                isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }),
                titleVisibility: .visible,
                presenting: pendingRestore
            ) { backup in
                Button("Ganti data", role: .destructive) { restore(backup) }
            } message: { backup in
                Text("Cadangan \(Fmt.day(backup.exportedAt)): \(backup.wallets.count) dompet, \(backup.entries.count) transaksi, \(backup.goals.count) target. Data yang ada sekarang akan terhapus.")
            }
            .alert(
                message ?? "",
                isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })
            ) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var backupFilename: String {
        "valore-\(Date.now.formatted(.iso8601.year().month().day()))"
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func prepareExport() {
        do {
            exportDocument = BackupDocument(data: try BackupService.snapshot(from: context).encoded())
            showingExporter = true
        } catch {
            message = "Gagal menyiapkan cadangan: \(error.localizedDescription)"
        }
    }

    private func loadBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            pendingRestore = try BackupFile.decode(Data(contentsOf: url))
        } catch {
            message = "File cadangan tidak bisa dibaca: \(error.localizedDescription)"
        }
    }

    private func restore(_ backup: BackupFile) {
        do {
            try BackupService.restore(backup, into: context)
            message = "Data berhasil dipulihkan."
        } catch {
            message = "Gagal memulihkan: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
