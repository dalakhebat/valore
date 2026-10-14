import Foundation

/// Format file cadangan JSON. Naikkan `currentVersion` kalau strukturnya berubah.
struct BackupFile: Codable, Equatable {
    static let currentVersion = 1

    var version: Int
    var exportedAt: Date
    var wallets: [WalletDTO]
    var entries: [EntryDTO]
    var goals: [GoalDTO]

    struct WalletDTO: Codable, Equatable {
        var id: UUID
        var name: String
        var symbol: String
        var initialBalance: Int
        var createdAt: Date
    }

    struct EntryDTO: Codable, Equatable {
        var id: UUID
        var amount: Int
        var kind: String
        var category: String
        var note: String
        var date: Date
        var walletID: UUID?
    }

    struct GoalDTO: Codable, Equatable {
        var id: UUID
        var name: String
        var symbol: String
        var target: Int
        var deadline: Date?
        var createdAt: Date
        var deposits: [DepositDTO]
    }

    struct DepositDTO: Codable, Equatable {
        var id: UUID
        var amount: Int
        var date: Date
        var note: String
    }
}

enum BackupError: LocalizedError, Equatable {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "File cadangan versi \(version) dibuat oleh versi VALORE yang lebih baru. Update app dulu."
        }
    }
}

extension BackupFile {
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(BackupFile.self, from: data)
        guard file.version <= currentVersion else { throw BackupError.unsupportedVersion(file.version) }
        return file
    }
}
