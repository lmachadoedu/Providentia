import SwiftUI

struct ExpenseEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ExpenseStore

    let month: Date
    var expense: Expense?

    @State private var name = ""
    @State private var amount = ""
    @State private var hasDue = true
    @State private var dueDay = 10
    @State private var recurring = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Despesa") {
                    TextField("Ex.: Energia", text: $name)
                    TextField("R$ 0,00", text: $amount)
                        .keyboardType(.decimalPad)
                }

                Section("Vencimento") {
                    Toggle("Adicionar vencimento", isOn: $hasDue)
                    if hasDue {
                        Stepper("Dia \(dueDay)", value: $dueDay, in: 1...31)
                    }
                }

                Section {
                    Toggle("Repetir todos os meses", isOn: $recurring)
                } footer: {
                    Text("Se ativado, a despesa reaparece nos próximos meses com valor zerado para você preencher.")
                }

                if let expense {
                    Section {
                        Button("Excluir despesa", role: .destructive) {
                            store.delete(expense)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(expense == nil ? "Nova despesa" : "Editar despesa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = expense {
                    name = e.name
                    amount = String(format: "%.2f", e.amount).replacingOccurrences(of: ".", with: ",")
                    hasDue = e.dueDay != nil
                    dueDay = e.dueDay ?? 10
                    recurring = e.recurring
                }
            }
        }
    }

    private func save() {
        let cleaned = amount
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")
        let normalized: String
        if cleaned.contains(",") {
            normalized = cleaned.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else {
            normalized = cleaned
        }
        let value = Double(normalized) ?? 0

        if var e = expense {
            e.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            e.amount = value
            e.dueDay = hasDue ? dueDay : nil
            e.recurring = recurring
            store.update(e)
        } else {
            store.add(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: value,
                dueDay: hasDue ? dueDay : nil,
                recurring: recurring,
                date: month
            )
        }
        dismiss()
    }
}
