import SwiftUI

struct UsageMenuView: View {
    @ObservedObject var monitor: UsageMonitor
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let error = monitor.state.errorMessage {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                sessionSection
                Divider()
                weekSection
            }

            Divider()

            HStack {
                Text("Actualizado \(monitor.state.lastUpdated.formatted(date: .omitted, time: .standard))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }

            HStack {
                Button("Actualizar") { monitor.refresh() }
                Spacer()
                Button("Salir") { NSApp.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 260)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private var sessionSection: some View {
        let s = monitor.state
        return VStack(alignment: .leading, spacing: 6) {
            Text("Current session")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if s.hasActiveBlock {
                Text("\(s.sessionPercent)%")
                    .font(.system(size: 32, weight: .semibold))

                ProgressView(value: min(Double(s.sessionPercent) / 100, 1))
                    .tint(s.sessionPercent > 85 ? .red : .accentColor)

                Text("Se reinicia en \(s.timeRemainingText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Sin sesión activa")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weekSection: some View {
        let s = monitor.state
        return VStack(alignment: .leading, spacing: 6) {
            Text("Current week")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(s.weeklyPercent)%")
                .font(.system(size: 32, weight: .semibold))

            ProgressView(value: min(Double(s.weeklyPercent) / 100, 1))
                .tint(s.weeklyPercent > 85 ? .red : .accentColor)

            Text("Se reinicia \(s.weeklyResetText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
