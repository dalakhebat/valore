import SwiftData
import SwiftUI

struct EntryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @State private var search = ""
    @State private var kindFilter: EntryKind?
    @State private var showingNew = false
    @State private var editing: LedgerEntry?
    @State private var deleteBlockedMessage: String?

    var body: some View {
        let groups = dayGroups

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: "Transaksi") {
                        BrutIconButton(symbol: "plus", label: "Catat transaksi", fill: Permen.cyan) { showingNew = true }
                    }

                    if entries.isEmpty {
                        EmptyCard(
                            symbol: "tray",
                            title: "Belum ada transaksi",
                            message: "Catat pemasukan atau pengeluaran pertamamu.",
                            actionTitle: "Catat transaksi",
                            action: { showingNew = true }
                        )
                    } else {
                        searchField
                        filterBar

                        if groups.isEmpty {
                            EmptyCard(symbol: "magnifyingglass", title: "Tidak ketemu", message: "Coba kata lain atau lepas filternya.")
                        }

                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    FieldLabel(Fmt.day(group.day))
                                    Spacer()
                                    Text(Fmt.rupiah(group.net, signed: true))
                                        .font(.jakarta(13, .extraBold))
                                        .foregroundStyle(group.net > 0 ? Permen.jade : Permen.ink)
                                }
                                VStack(spacing: 0) {
                                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, entry in
                                        if index > 0 { InkDivider() }
                                        Button { editing = entry } label: {
                                            EntryRow(entry: entry)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 12)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                if let problem = entry.deletionProblem {
                                                    deleteBlockedMessage = problem
                                                } else {
                                                    context.delete(entry)
                                                    try? context.save()
                                                }
                                            } label: {
                                                Label("Hapus transaksi", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .background(BrutShape())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PermenBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNew) { EntryFormView() }
            .sheet(item: $editing) { entry in EntryFormView(entry: entry) }
            .alert(
                deleteBlockedMessage ?? "",
                isPresented: Binding(get: { deleteBlockedMessage != nil }, set: { if !$0 { deleteBlockedMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Permen.ink)
            TextField("Cari catatan, kategori, dompet", text: $search)
                .font(.jakarta(16, .medium))
                .foregroundStyle(Permen.ink)
                .submitLabel(.search)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Permen.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus pencarian")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BrutShape(fill: Permen.surface, radius: Permen.radiusField, shadow: 0))
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterChip(title: "Semua", isSelected: kindFilter == nil) { kindFilter = nil }
            ForEach(EntryKind.allCases) { kind in
                FilterChip(title: kind.label, isSelected: kindFilter == kind) { kindFilter = kind }
            }
        }
    }

    private struct DayGroup: Identifiable {
        let day: Date
        let items: [LedgerEntry]
        var id: Date { day }
        var net: Int { items.reduce(0) { $0 + $1.signedAmount } }
    }

    private var dayGroups: [DayGroup] {
        let calendar = Calendar.current
        let visible = entries.filter { entry in
            (kindFilter == nil || entry.kind == kindFilter) && (search.isEmpty || entry.matches(search))
        }
        let grouped = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { DayGroup(day: $0, items: grouped[$0] ?? []) }
    }
}

#Preview {
    EntryListView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
