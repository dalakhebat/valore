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

    init(entry: LedgerEntry? = nil) {
        self.entry = entry
        _kind = State(initialValue: entry?.kind ?? .expense)
        _amount = State(initialValue: entry?.amount ?? 0)
        _category = State(initialValue: entry?.category ?? .makan)
        _wallet = State(initialValue: entry?.wallet)
        _date = State(initialValue: entry?.date ?? .now)
        _note = State(initialValue: entry?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Jenis", selection: $kind) {
                        ForEach(EntryKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Jumlah") {
                    RupiahField(amount: $amount)
                }

                Section {
                    Picker("Kategori", selection: $category) {
                        ForEach(EntryCategory.options(for: kind)) { category in
                            Label(category.label, systemImage: category.symbol).tag(category)
                        }
                    }
                    Picker("Dompet", selection: $wallet) {
                        ForEach(wallets) { wallet in
                            Label(wallet.name, systemImage: wallet.symbol).tag(Optional(wallet))
                        }
                    }
                    DatePicker("Tanggal", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Catatan (opsional)", text: $note, axis: .vertical)
                }

                if entry != nil {
                    Section {
                        Button("Hapus transaksi", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(entry == nil ? "Catat transaksi" : "Ubah transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan", action: save)
                        .disabled(amount <= 0 || wallet == nil)
                }
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
        }
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
