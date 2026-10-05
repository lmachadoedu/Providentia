import Foundation

final class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = [] { didSet { save() } }
    @Published var templates: [ExpenseTemplate] = [] { didSet { saveTemplates() } }

    private let expenseKey = "expenses.v1"
    private let templateKey = "templates.v1"

    init() {
        load()
        loadTemplates()
        seedMonthIfNeeded(Date())
    }

    func monthKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: date)
    }

    func expenses(for date: Date) -> [Expense] {
        let key = monthKey(date)
        return expenses.filter { $0.monthKey == key }.sorted {
            ($0.dueDay ?? 99, $0.name) < ($1.dueDay ?? 99, $1.name)
        }
    }

    func add(name: String, amount: Double, dueDay: Int?, recurring: Bool, date: Date) {
        let key = monthKey(date)
        expenses.append(Expense(name: name, amount: amount, dueDay: dueDay, recurring: recurring, monthKey: key))
        if recurring && !templates.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            templates.append(ExpenseTemplate(name: name, dueDay: dueDay))
        }
    }

    func update(_ expense: Expense) {
        guard let i = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[i] = expense
        if expense.recurring {
            if let ti = templates.firstIndex(where: { $0.name.caseInsensitiveCompare(expense.name) == .orderedSame }) {
                templates[ti].dueDay = expense.dueDay
            } else {
                templates.append(ExpenseTemplate(name: expense.name, dueDay: expense.dueDay))
            }
        }
    }

    func delete(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    func seedMonthIfNeeded(_ date: Date) {
        let key = monthKey(date)
        let existing = Set(expenses.filter { $0.monthKey == key }.map { $0.name.lowercased() })
        for t in templates where !existing.contains(t.name.lowercased()) {
            expenses.append(Expense(name: t.name, amount: 0, dueDay: t.dueDay, recurring: true, monthKey: key))
        }
    }

    func backupData() -> Data? {
        try? JSONEncoder().encode(BackupPayload(expenses: expenses, templates: templates))
    }

    func restore(from data: Data) throws {
        let payload = try JSONDecoder().decode(BackupPayload.self, from: data)
        expenses = payload.expenses
        templates = payload.templates
    }

    private func save() {
        if let d = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(d, forKey: expenseKey)
        }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: expenseKey),
           let v = try? JSONDecoder().decode([Expense].self, from: d) {
            expenses = v
        }
    }

    private func saveTemplates() {
        if let d = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(d, forKey: templateKey)
        }
    }

    private func loadTemplates() {
        if let d = UserDefaults.standard.data(forKey: templateKey),
           let v = try? JSONDecoder().decode([ExpenseTemplate].self, from: d) {
            templates = v
        }
    }
}
