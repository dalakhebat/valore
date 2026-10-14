import SwiftData
import SwiftUI

struct EntryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @State private var search = ""
    @State private var kindFilter: EntryKind?
    @State private var showingNew = false
    @State private var editing: LedgerEntry?

    var body: some View {
        let groups = dayGroups

        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Belum ada transaksi",
                        systemImage: "tray",
                        description: Text("Catat pemasukan atau pengeluaran pertamamu.")
                    )
                } else {
                    List {
                        // Chip filter sebagai baris pertama: tetap terlihat walau hasilnya kosong,
                        // dan judul besar navigasi tidak tertutup.
                        Section {
                            filterBar
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }

                        if groups.isEmpty {
                            Section {
                                ContentUnavailableView.search(text: search)
                                    .listRowBackground(Color.clear)
                            }
                        }

                        ForEach(groups) { group in
                            Section {
                                ForEach(group.items) { entry in
                                    Button { editing = entry } label: {
                                        EntryRow(entry: entry)
                                    }
                                    .listRowBackground(Palette.card)
                                }
                                .onDelete { offsets in
                                    for index in offsets { context.delete(group.items[index]) }
                                    try? context.save()
                                }
                            } header: {
                                HStack {
                                    Text(Fmt.day(group.day))
                                    Spacer()
                                    Text(Fmt.rupiah(group.net, signed: true))
                                        .monospacedDigit()
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.background)
            .navigationTitle("Transaksi")
            .searchable(text: $search, prompt: "Cari catatan, kategori, dompet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Catat transaksi")
                }
            }
            .sheet(isPresented: $showingNew) { EntryFormView() }
            .sheet(item: $editing) { entry in EntryFormView(entry: entry) }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterChip(title: "Semua", isSelected: kindFilter == nil) { kindFilter = nil }
            ForEach(EntryKind.allCases) { kind in
                FilterChip(title: kind.label, isSelected: kindFilter == kind) { kindFilter = kind }
            }
            Spacer(minLength: 0)
        }
        .buttonStyle(.borderless)
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
