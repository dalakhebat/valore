import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @AppStorage("displayName") private var displayName = ""

    @State private var editingWallet: Wallet?
    @State private var showingNewWallet = false
    @State private var exportDocument: BackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingRestore: BackupFile?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: "Pengaturan", closeTitle: "Selesai") { dismiss() }

                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel("Nama panggilan")
                    BrutTextField(prompt: "Mis. Jey", text: $displayName)
                        .textInputAutocapitalization(.words)
                    note("Dipakai untuk sapaan di Beranda.")
                }
                .brut()

                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel("Dompet")
                    VStack(spacing: 0) {
                        ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                            if index > 0 { InkDivider() }
                            Button { editingWallet = wallet } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: wallet.symbol)
                                        .font(.system(size: 14, weight: .bold))
                                        .frame(width: 34, height: 34)
                                        .background(Circle().fill(Permen.candies[index % Permen.candies.count]))
                                        .overlay(Circle().strokeBorder(Permen.ink, lineWidth: 1.5))
                                    Text(wallet.name)
                                        .font(.jakarta(16, .bold))
                                    Spacer()
                                    Text(Fmt.rupiah(wallet.balance))
                                        .font(.jakarta(15, .extraBold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Permen.muted)
                                }
                                .foregroundStyle(Permen.ink)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button { showingNewWallet = true } label: {
                        Label("Tambah dompet", systemImage: "plus")
                    }
                    .buttonStyle(BrutButtonStyle(fill: Permen.lemon, fullWidth: true))
                    note("Saldo dompet = saldo awal + pemasukan − pengeluaran.")
                }
                .brut()

                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel("Cadangan data")
                    // Exporter & importer ditempel di view berbeda: dua-duanya di satu view bikin salah satu tidak jalan.
                    Button(action: prepareExport) {
                        Label("Ekspor cadangan (JSON)", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(BrutButtonStyle(fill: Permen.cyanSoft, fullWidth: true))
                    .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .json, defaultFilename: backupFilename) { result in
                        if case .failure(let error) = result { message = "Gagal ekspor: \(error.localizedDescription)" }
                    }

                    Button { showingImporter = true } label: {
                        Label("Pulihkan dari cadangan", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(BrutButtonStyle(fill: Permen.surface, fullWidth: true))
                    .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], onCompletion: loadBackup)

                    note("Semua data cuma tersimpan di iPhone ini. Ekspor berkala ke Files atau iCloud Drive supaya aman kalau HP hilang atau app terhapus.")
                }
                .brut()

                HStack {
                    FieldLabel("Versi")
                    Spacer()
                    Text(appVersion)
                        .font(.jakarta(14, .bold))
                        .foregroundStyle(Permen.ink)
                }
                .brut(shadow: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PermenBackground())
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

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.jakarta(13, .medium))
            .foregroundStyle(Permen.muted)
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
