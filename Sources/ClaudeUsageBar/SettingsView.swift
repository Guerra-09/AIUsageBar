import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.sessionTokenLimit) private var sessionLimit: Int = SettingsKeys.defaultSessionLimit
    @AppStorage(SettingsKeys.weeklyTokenLimit) private var weeklyLimit: Int = SettingsKeys.defaultWeeklyLimit
    @AppStorage(SettingsKeys.weeklyResetWeekday) private var weeklyWeekday: Int = SettingsKeys.defaultWeekday

    @Environment(\.dismiss) private var dismiss

    private let weekdayNames = ["", "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calibrar límites")
                .font(.headline)

            Text("Abre Claude.ai, mira el % real de tu sesión y semana, y ajusta estos límites para que coincida.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Límite tokens · sesión (5h)")
                    .font(.caption)
                TextField("tokens", value: $sessionLimit, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Límite tokens · semana")
                    .font(.caption)
                TextField("tokens", value: $weeklyLimit, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Día de reinicio semanal")
                    .font(.caption)
                Picker("", selection: $weeklyWeekday) {
                    ForEach(1...7, id: \.self) { day in
                        Text(weekdayNames[day]).tag(day)
                    }
                }
                .labelsHidden()
            }

            Divider()

            HStack {
                Spacer()
                Button("Listo") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}
