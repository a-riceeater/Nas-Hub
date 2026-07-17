import SwiftUI
@main struct Nas_HubApp: App {
    #if PUSH_NOTIFICATIONS
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif
    @StateObject private var app = AppState()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup { RootView().environmentObject(app) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await app.refresh(); await app.connectLive() } }
                else if phase == .background { app.socket.disconnect() }
            }
    }
}
