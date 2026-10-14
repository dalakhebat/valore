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
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("Jenis", selection: $kind) {
                        ForEach(EntryKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    RupiahField(amount: $amount, large: true)
                        .padding(.vertical, 14)
                        .card()

                    categoryCard
                    walletCard

                    VStack(spacing: 0) {
                        DatePicker("Tanggal", selection: $date)
                            .padding(.vertical, 6)
                        Divider()
                        TextField("Catatan (opsional)", text: $note, axis: .vertical)
                            .padding(.vertical, 12)
                    }
                    .card(padding: 16)

                    if entry != nil {
                        Button("Hapus transaksi", role: .destructive) { confirmingDelete = true }
                            .padding(.top, 4)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.background)
            .safeAreaInset(edge: .bottom) {
                Button("Simpan", action: save)
                    .buttonStyle(InkButtonStyle(fullWidth: true))
                    .disabled(amount <= 0 || wallet == nil)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Palette.background)
            }
            .navigationTitle(entry == nil ? "Catat transaksi" : "Ubah transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
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

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kategori")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), alignment: .center, spacing: 16) {
                ForEach(EntryCategory.options(for: kind)) { option in
                    let isSelected = option == category
                    Button { category = option } label: {
                        VStack(spacing: 6) {
                            CategoryIcon(category: option, size: 52)
                                .overlay(Circle().strokeBorder(Palette.ink, lineWidth: isSelected ? 2.5 : 0))
                            Text(option.label)
                                .font(.caption2.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .card()
    }

    private var walletCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dompet")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(wallets) { option in
                        FilterChip(title: option.name, isSelected: option == wallet, unselectedFill: Palette.background) {
                            wallet = option
                        }
                    }
                }
            }
        }
        .card()
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
