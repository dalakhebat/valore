import SwiftData
import SwiftUI

/// Form catat/ubah transaksi. Perubahan baru disimpan saat menekan "Simpan".
struct EntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]

    private let entry: LedgerEntry?
    @State private var kind: EntryKind
    @State private var amount: Int
    @State private var category: EntryCategory
    @State private var wallet: Wallet?
    @State private var date: Date
    @State private var note: String
    @State private var confirmingDelete = false
    @State private var deleteBlockedMessage: String?

    init(entry: LedgerEntry? = nil, kind: EntryKind = .expense) {
        self.entry = entry
        let initialKind = entry?.kind ?? kind
        _kind = State(initialValue: initialKind)
        _amount = State(initialValue: entry?.amount ?? 0)
        _category = State(initialValue: entry?.category ?? EntryCategory.options(for: initialKind).first ?? .lainnya)
        _wallet = State(initialValue: entry?.wallet)
        _date = State(initialValue: entry?.date ?? .now)
        _note = State(initialValue: entry?.note ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: entry == nil ? "Catat transaksi" : "Ubah transaksi") { dismiss() }

                BrutSegmented(options: EntryKind.allCases, selection: $kind) { $0.label }

                VStack(spacing: 8) {
                    FieldLabel("Jumlah")
                    RupiahField(amount: $amount, large: true)
                    if let balanceProblem {
                        Sticker(text: balanceProblem, fill: Permen.pinkSoft)
                    } else if kind == .expense, let wallet {
                        Text("Saldo \(wallet.name) \(Fmt.rupiah(BalanceRule.spendable(current: wallet.balance, removing: previousSignedInSelectedWallet)))")
                            .font(.jakarta(13, .semibold))
                            .foregroundStyle(Permen.muted)
                    }
                }
                .frame(maxWidth: .infinity)
                .brut(padding: 18)

                categoryCard
                walletCard

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        FieldLabel("Tanggal")
                        Spacer()
                        DatePicker("Tanggal", selection: $date)
                            .labelsHidden()
                    }
                    FieldLabel("Catatan")
                    BrutTextField(prompt: "Opsional, mis. makan siang kantor", text: $note, axis: .vertical)
                }
                .brut()

                if entry != nil {
                    Button("Hapus transaksi") {
                        if let problem = entry?.deletionProblem {
                            deleteBlockedMessage = problem
                        } else {
                            confirmingDelete = true
                        }
                    }
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
                .disabled(amount <= 0 || wallet == nil || balanceProblem != nil)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Permen.bg)
        }
        .onAppear {
            if wallet == nil { wallet = wallets.first }
        }
        .onChange(of: kind) { _, newKind in
            if !category.kinds.contains(newKind) {
                category = EntryCategory.options(for: newKind).first ?? .lainnya
            }
        }
        .confirmationDialog("Hapus transaksi ini?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Hapus", role: .destructive, action: delete)
        }
        .alert(
            deleteBlockedMessage ?? "",
            isPresented: Binding(get: { deleteBlockedMessage != nil }, set: { if !$0 { deleteBlockedMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Aturan saldo (tidak boleh minus)

    /// Nilai transaksi lama yang sudah terhitung di saldo dompet yang sedang dipilih.
    private var previousSignedInSelectedWallet: Int {
        guard let entry, let wallet, entry.wallet == wallet else { return 0 }
        return entry.signedAmount
    }

    /// Alasan transaksi ini tidak boleh disimpan karena bikin saldo minus, atau nil kalau aman.
    private var balanceProblem: String? {
        if let wallet, !BalanceRule.isAllowed(current: wallet.balance, removing: previousSignedInSelectedWallet, adding: amount * kind.sign) {
            let spendable = BalanceRule.spendable(current: wallet.balance, removing: previousSignedInSelectedWallet)
            return kind == .expense
                ? "Saldo \(wallet.name) cuma \(Fmt.rupiah(spendable))"
                : "Saldo \(wallet.name) jadi minus"
        }
        // Pindah dompet: dompet lama kehilangan transaksi ini (masalah kalau transaksinya pemasukan).
        if let entry, let previous = entry.wallet, previous != wallet,
           !BalanceRule.isAllowed(current: previous.balance, removing: entry.signedAmount) {
            return "Saldo \(previous.name) jadi minus kalau dipindah"
        }
        return nil
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("Kategori")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 14) {
                ForEach(EntryCategory.options(for: kind)) { option in
                    let isSelected = option == category
                    Button { category = option } label: {
                        VStack(spacing: 6) {
                            CategoryIcon(category: option, size: 50)
                                .background(Circle().fill(Permen.ink).offset(x: isSelected ? 3 : 0, y: isSelected ? 3 : 0))
                                .overlay(Circle().strokeBorder(Permen.ink, lineWidth: isSelected ? 3 : 0))
                            Text(option.label)
                                .font(.jakarta(11, isSelected ? .extraBold : .medium, relativeTo: .caption))
                                .foregroundStyle(Permen.ink)
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .brut()
    }

    private var walletCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            FieldLabel("Dompet")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(wallets) { option in
                        FilterChip(title: option.name, isSelected: option == wallet) { wallet = option }
                    }
                }
                .padding(.vertical, 2)
                .padding(.trailing, 4)
            }
        }
        .brut()
    }

    private func save() {
        let target: LedgerEntry
        if let entry {
            target = entry
        } else {
            target = LedgerEntry()
            context.insert(target)
        }
        target.kind = kind
        target.amount = amount
        target.category = category
        target.wallet = wallet
        target.date = date
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        dismiss()
    }

    private func delete() {
        if let entry {
            context.delete(entry)
            try? context.save()
        }
        dismiss()
    }
}

#Preview {
    EntryFormView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
