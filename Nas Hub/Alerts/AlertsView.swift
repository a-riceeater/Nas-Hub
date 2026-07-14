import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            Group {
                if app.alerts.isEmpty {
                    ContentUnavailableView("No alerts", systemImage: "checkmark.shield", description: Text("Your server has no alert history."))
                } else {
                    List(app.alerts) { alert in
                        NavigationLink { AlertDetail(alert: alert) } label: {
                            HStack(alignment: .top) {
                                Image(systemName: alert.status == "resolved" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(alert.severity == "critical" ? .red : .orange)
                                VStack(alignment: .leading) {
                                    Text(alert.title).font(.headline)
                                    Text(alert.message).font(.caption).foregroundStyle(.secondary)
                                    Text(Date(timeIntervalSince1970: alert.triggeredAt / 1000), style: .relative).font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
            .refreshable { await app.refresh() }
        }
    }
}

struct AlertDetail: View {
    let alert: AlertItem
    @EnvironmentObject var app: AppState
    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Severity", value: alert.severity.capitalized)
                LabeledContent("Status", value: alert.status.capitalized)
                Text(alert.message)
            }
            if alert.acknowledgedAt == nil && alert.status == "active" {
                Button("Acknowledge") { Task { try? await app.api.acknowledge(alert.id); await app.refresh() } }
            }
        }
        .navigationTitle(alert.title)
    }
}
