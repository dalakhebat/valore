import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Menerjemahkan isi database ke/dari `BackupFile`.
@MainActor
enum BackupService {
    static func snapshot(from context: ModelContext, now: Date = .now) throws -> BackupFile {
        let wallets = try context.fetch(FetchDescriptor<Wallet>(sortBy: [SortDescriptor(\.createdAt)]))
        let entries = try context.fetch(FetchDescriptor<LedgerEntry>(sortBy: [SortDescriptor(\.date)]))
        let goals = try context.fetch(FetchDescriptor<SavingGoal>(sortBy: [SortDescriptor(\.createdAt)]))

        return BackupFile(
            version: BackupFile.currentVersion,
            exportedAt: now,
            wallets: wallets.map {
                .init(id: $0.uuid, name: $0.name, symbol: $0.symbol, initialBalance: $0.initialBalance, createdAt: $0.createdAt)
            },
            entries: entries.map {
                .init(id: $0.uuid, amount: $0.amount, kind: $0.kindRaw, category: $0.categoryRaw, note: $0.note, date: $0.date, walletID: $0.wallet?.uuid)
            },
            goals: goals.map { goal in
                .init(
                    id: goal.uuid, name: goal.name, symbol: goal.symbol, target: goal.target,
                    deadline: goal.deadline, createdAt: goal.createdAt,
                    deposits: (goal.deposits ?? []).sorted { $0.date < $1.date }.map {
                        .init(id: $0.uuid, amount: $0.amount, date: $0.date, note: $0.note)
                    }
                )
            }
        )
    }

    /// Hapus semua data lalu isi ulang persis seperti di cadangan.
    static func restore(_ backup: BackupFile, into context: ModelContext) throws {
        try deleteAll(in: context)

        var walletsByID: [UUID: Wallet] = [:]
        for dto in backup.wallets {
            let wallet = Wallet(name: dto.name, symbol: dto.symbol, initialBalance: dto.initialBalance, createdAt: dto.createdAt)
            wallet.uuid = dto.id
            context.insert(wallet)
            walletsByID[dto.id] = wallet
        }

        for dto in backup.entries {
            let entry = LedgerEntry(amount: dto.amount, note: dto.note, date: dto.date)
            entry.uuid = dto.id
            entry.kindRaw = dto.kind
            entry.categoryRaw = dto.category
            context.insert(entry)
            entry.wallet = dto.walletID.flatMap { walletsByID[$0] }
        }

        for dto in backup.goals {
            let goal = SavingGoal(name: dto.name, symbol: dto.symbol, target: dto.target, deadline: dto.deadline, createdAt: dto.createdAt)
            goal.uuid = dto.id
            context.insert(goal)
            for depositDTO in dto.deposits {
                let deposit = GoalDeposit(amount: depositDTO.amount, date: depositDTO.date, note: depositDTO.note)
                deposit.uuid = depositDTO.id
                context.insert(deposit)
                deposit.goal = goal
            }
        }

        try context.save()
    }

    static func deleteAll(in context: ModelContext) throws {
        // Satu per satu (bukan batch delete) supaya @Query di layar langsung ikut ter-update.
        for deposit in try context.fetch(FetchDescriptor<GoalDeposit>()) { context.delete(deposit) }
        for goal in try context.fetch(FetchDescriptor<SavingGoal>()) { context.delete(goal) }
        for entry in try context.fetch(FetchDescriptor<LedgerEntry>()) { context.delete(entry) }
        for wallet in try context.fetch(FetchDescriptor<Wallet>()) { context.delete(wallet) }
        try context.save()
    }
}

/// Pembungkus data JSON untuk `fileExporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
