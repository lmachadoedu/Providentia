import Foundation

struct Expense: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var amount: Double
    var dueDay: Int?
    var recurring: Bool
    var isPaid: Bool = false
    var monthKey: String
}

struct ExpenseTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var dueDay: Int?
}

struct BackupPayload: Codable {
    var expenses: [Expense]
    var templates: [ExpenseTemplate]
}
