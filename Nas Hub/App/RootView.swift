import SwiftUI
struct RootView:View{@EnvironmentObject var app:AppState;var body:some View{switch app.phase{case .restoring:ProgressView("Restoring session…");case .signedOut:LoginView();case .signedIn:TabView{DashboardView().tabItem{Label("Dashboard",systemImage:"gauge.with.dots.needle.50percent")};AlertsView().tabItem{Label("Alerts",systemImage:"exclamationmark.triangle")}.badge(app.alerts.filter{$0.status=="active"}.count);SettingsView().tabItem{Label("Settings",systemImage:"gear")}}}}}

