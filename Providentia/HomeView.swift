import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ExpenseStore
    @AppStorage("userName") private var userName = ""
    @AppStorage("profileImage") private var profileImage = Data()

    @State private var month = Date()
    @State private var showAdd = false
    @State private var editing: Expense?

    private var items: [Expense] { store.expenses(for: month) }
    private var total: Double { items.reduce(0) { $0 + $1.amount } }
    private var paid: Double { items.filter(\.isPaid).reduce(0) { $0 + $1.amount } }
    private var progress: Double {
        items.isEmpty ? 0 : Double(items.filter(\.isPaid).count) / Double(items.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quote
                    monthPicker
                    summary
                    expensesList
                }
                .padding()
                .padding(.bottom, 70)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .frame(width: 58, height: 58)
                        .background(.green.gradient)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(radius: 8, y: 4)
                }
                .padding(22)
            }
            .sheet(isPresented: $showAdd) { ExpenseEditor(month: month) }
            .sheet(item: $editing) { ExpenseEditor(month: month, expense: $0) }
            .onChange(of: month) { _, value in store.seedMonthIfNeeded(value) }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            profileAvatar
            VStack(alignment: .leading, spacing: 2) {
                Text("Olá, \(userName)!")
                    .font(.title2.bold())
                Text(month.formatted(.dateTime.month(.wide).year()))
    .font(.subheadline)
    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let ui = UIImage(data: profileImage) {
            Image(uiImage: ui).resizable().scaledToFill()
                .frame(width: 52, height: 52).clipShape(Circle())
        } else {
            Circle().fill(.green.opacity(0.16)).frame(width: 52, height: 52)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.green))
        }
    }

    private var quote: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: "quote.opening").foregroundStyle(.green)
            Text("“A confiança na Providência Divina é a fé firme e viva de que Deus nos pode ajudar e nos ajudará.”")
                .font(.subheadline)
                .italic()
            Text("Santa Teresa de Calcutá")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.green.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var monthPicker: some View {
        HStack {
            Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month)! } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
           Text(month.formatted(.dateTime.month(.wide).year()))
    .font(.headline)
            Spacer()
            Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month)! } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal, 6)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                valueBox("Total", total, .primary)
                valueBox("Pago", paid, .green)
                valueBox("Falta", total - paid, total - paid > 0 ? .orange : .green)
            }
            ProgressView(value: progress).tint(.green)
            Text("\(items.filter(\.isPaid).count) de \(items.count) contas pagas")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func valueBox(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .currency(code: "BRL"))
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expensesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Despesas").font(.title3.bold())
                Spacer()
                Text("\(items.count)").font(.caption.bold())
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(.green.opacity(0.12)).clipShape(Capsule())
            }

            if items.isEmpty {
                ContentUnavailableView(
                    "Nenhuma despesa",
                    systemImage: "checklist",
                    description: Text("Toque no + para adicionar sua primeira conta.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }

            ForEach(items) { expense in
                HStack(spacing: 12) {
                    Button {
                        var e = expense
                        e.isPaid.toggle()
                        store.update(e)
                    } label: {
                        Image(systemName: expense.isPaid ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(expense.isPaid ? .green : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(expense.name)
                            .font(.headline)
                            .strikethrough(expense.isPaid)
                        if let d = expense.dueDay {
                            Text(dueText(day: d, paid: expense.isPaid))
                                .font(.caption)
                                .foregroundStyle(dueColor(day: d, paid: expense.isPaid))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(expense.amount, format: .currency(code: "BRL"))
                            .fontWeight(.semibold)
                        if expense.isPaid {
                            Text("Pago").font(.caption2.bold()).foregroundStyle(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .contentShape(Rectangle())
                .onTapGesture { editing = expense }
            }
        }
    }

    private func dueText(day: Int, paid: Bool) -> String {
        if paid { return "Pago" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        let safeDay = min(day, cal.range(of: .day, in: .month, for: month)?.count ?? day)
        guard let due = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: safeDay)) else {
            return "Vence dia \(day)"
        }
        if cal.isDateInToday(due) { return "Vence hoje" }
        let delta = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: due).day ?? 0
        if store.monthKey(month) == store.monthKey(Date()) {
            if delta == 1 { return "Vence amanhã" }
            if delta < 0 { return "Vencida há \(abs(delta)) dia\(abs(delta) == 1 ? "" : "s")" }
        }
        return "Vence dia \(day)"
    }

    private func dueColor(day: Int, paid: Bool) -> Color {
        if paid { return .green }
        guard store.monthKey(month) == store.monthKey(Date()) else { return .secondary }
        let today = Calendar.current.component(.day, from: Date())
        if day < today { return .red }
        if day - today <= 2 { return .orange }
        return .secondary
    }
}
