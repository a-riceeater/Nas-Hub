import SwiftUI

struct RootView:View{
    @EnvironmentObject var app:AppState
    var body:some View{
        switch app.phase {
        case .restoring: ProgressView("Restoring session…")
        case .signedOut: LoginView()
        case .setup: SetupView()
        case .signedIn:
            TabView(selection:$app.selectedTab){
                DashboardView().tabItem{Label("Dashboard",systemImage:"gauge.with.dots.needle.50percent")}.tag(AppTab.dashboard)
                AlertsView().tabItem{Label("Alerts",systemImage:"exclamationmark.triangle")}.badge(app.alerts.filter{$0.status=="active"}.count).tag(AppTab.alerts)
                SettingsView().tabItem{Label("Settings",systemImage:"gear")}.tag(AppTab.settings)
            }
        }
    }
}
