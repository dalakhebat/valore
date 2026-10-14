import SwiftData
import SwiftUI

struct WalletFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    static let symbols = [
        "banknote.fill", "building.columns.fill", "creditcard.fill",
        "iphone", "wallet.pass.fill", "dollarsign.circle.fill",
    ]

    private let wallet: Wallet?
    /// Dompet terakhir tidak boleh dihapus, karena transaksi butuh dompet.
    private let canDelete: Bool
    @State private var name: String
    @State private var symbol: String
    @State private var initialBalance: Int
    @State private var confirmingDelete = false

    init(wallet: Wallet? = nil, canDelete: Bool = false) {
        self.wallet = wallet
        self.canDelete = canDelete
        _name = State(initialValue: wallet?.name ?? "")
        _symbol = State(initialValue: wallet?.symbol ?? "wallet.pass.fill")
        _initialBalance = State(initialValue: wallet?.initialBalance ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nama dompet (mis. BCA, GoPay)", text: $name)
                    SymbolPicker(symbols: Self.symbols, selection: $symbol)
                }

                Section {
                    RupiahField(amount: $initialBalance)
                } header: {
                    Text("Saldo awal")
                } footer: {
                    Text("Isi saldo saat dompet ini mulai dicatat di VALORE.")
                }

                if wallet != nil && canDelete {
                    Section {
                        Button("Hapus dompet", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(wallet == nil ? "Dompet baru" : "Ubah dompet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("Hapus dompet \"\(wallet?.name ?? "")\"?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Hapus dompet & \(wallet?.entries?.count ?? 0) transaksinya", role: .destructive, action: delete)
            } message: {
                Text("Transaksi di dompet ini ikut terhapus dan tidak bisa dikembalikan.")
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let target: Wallet
        if let wallet {
            target = wallet
        } else {
            target = Wallet(name: trimmedName)
            context.insert(target)
        }
        target.name = trimmedName
        target.symbol = symbol
        target.initialBalance = initialBalance
        try? context.save()
        dismiss()
    }

    private func delete() {
        if let wallet {
            context.delete(wallet)
            try? context.save()
        }
        dismiss()
    }
}
