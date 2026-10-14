import SwiftUI

extension EntryCategory {
    var color: Color {
        switch self {
        case .makan: .orange
        case .transportasi: .blue
        case .belanja: .pink
        case .tagihan: .indigo
        case .hiburan: .purple
        case .kesehatan: .red
        case .pendidikan: .cyan
        case .keluarga: .brown
        case .gaji: .green
        case .usaha: .teal
        case .investasi: .mint
        case .bonus: .yellow
        case .lainnya: .gray
        }
    }
}

extension GoalPace {
    var color: Color {
        switch self {
        case .done: .green
        case .ahead: .teal
        case .onTrack: .blue
        case .behind: .orange
        case .overdue: .red
        case .noDeadline: .gray
        }
    }
}

enum Brand {
    static let gradient = LinearGradient(colors: [.teal, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
}
