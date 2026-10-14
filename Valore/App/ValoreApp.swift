import SwiftData
import SwiftUI

@main
struct ValoreApp: App {
    private let container: ModelContainer

    init() {
        do {
            #if DEBUG
            // `-sampleData`: jalan dengan data contoh di memori (buat screenshot), data asli tidak disentuh.
            if CommandLine.arguments.contains("-sampleData") {
                container = try SampleData.makeContainer()
                return
            }
            #endif
            container = try ValoreSchema.container()
        } catch {
            fatalError("Gagal membuka database Valore: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
