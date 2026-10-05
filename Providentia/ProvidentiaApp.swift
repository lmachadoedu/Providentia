import SwiftUI

@main
struct ProvidentiaApp: App {
    @StateObject private var store = ExpenseStore()
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
                .tint(.green)
        }
    }
}
