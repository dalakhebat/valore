import SwiftData

enum ValoreSchema {
    static let models: [any PersistentModel.Type] = [Wallet.self, LedgerEntry.self, SavingGoal.self, GoalDeposit.self]

    static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(for: Schema(models), configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory))
    }
}
