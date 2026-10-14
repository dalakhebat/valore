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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: wallet == nil ? "Dompet baru" : "Ubah dompet") { dismiss() }

                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel("Nama dompet")
                    BrutTextField(prompt: "Mis. BCA, GoPay", text: $name)
                    FieldLabel("Ikon")
                        .padding(.top, 4)
                    SymbolPicker(symbols: Self.symbols, selection: $symbol)
                }
                .brut()

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel("Saldo awal")
                    RupiahField(amount: $initialBalance)
                    if let balanceProblem {
                        Sticker(text: balanceProblem, fill: Permen.pinkSoft)
                    }
                    Text("Isi saldo saat dompet ini mulai dicatat di VALORE.")
                        .font(.jakarta(13, .medium))
                        .foregroundStyle(Permen.muted)
                }
                .brut()

                if wallet != nil && canDelete {
                    Button("Hapus dompet") { confirmingDelete = true }
                        .buttonStyle(BrutButtonStyle(fill: Permen.pinkSoft, fullWidth: true))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PermenBackground())
        .safeAreaInset(edge: .bottom) {
            Button("Simpan", action: save)
                .buttonStyle(BrutButtonStyle(fullWidth: true))
                .disabled(trimmedName.isEmpty || balanceProblem != nil)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Permen.bg)
        }
        .confirmationDialog("Hapus dompet \"\(wallet?.name ?? "")\"?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Hapus dompet & \(wallet?.entries?.count ?? 0) transaksinya", role: .destructive, action: delete)
        } message: {
            Text("Transaksi di dompet ini ikut terhapus dan tidak bisa dikembalikan.")
        }
    }

    /// Saldo awal tidak boleh diturunkan sampai saldo dompet jadi minus.
    private var balanceProblem: String? {
        guard let wallet else { return nil }
        let result = BalanceRule.resultingBalance(current: wallet.balance, removing: wallet.initialBalance, adding: initialBalance)
        return result < 0 ? "Saldo dompet jadi \(Fmt.rupiah(result))" : nil
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
