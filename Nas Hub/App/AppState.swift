import Foundation

@MainActor final class AppState: ObservableObject {
    enum Phase { case restoring, signedOut, setup, signedIn }
    @Published var phase: Phase = .restoring
    @Published var user: User?; @Published var server: Server?; @Published var metric: Metric?
    @Published var history: [Metric] = []; @Published var alerts: [AlertItem] = []
    @Published var healthStatus = "connecting"; @Published var error: String?; @Published var loading = false
    let socket=WebSocketManager(); let store:TokenStore; let api:APIClient

    init() {
        let store=KeychainStore();self.store=store
        self.api=APIClient(baseURLs:Self.savedURLs(),store:store)
        socket.onMetric={ [weak self] m in self?.metric=m;self?.healthStatus="healthy";self?.history.append(m);if let count=self?.history.count,count>300{self?.history.removeFirst(count-300)} }
        socket.onReconnect={ [weak self] in Task{await self?.refresh();await self?.connectLive()} }
        Task{await restore()}
    }
    static func savedURLs()->[URL]{[UserDefaults.standard.string(forKey:"localServerURL"),UserDefaults.standard.string(forKey:"publicServerURL")].compactMap{$0?.trimmed}.filter{!$0.isEmpty}.compactMap(URL.init(string:))}
    func restore() async { guard (try? store.load()) != nil else{phase = .signedOut;return};do{user=try await api.me();phase=user?.setupCompleted == false ? .setup:.signedIn;await refresh();await connectLive()}catch{try? store.clear();phase = .signedOut} }
    func login(localURL:String,publicURL:String,identifier:String,password:String) async {
        let urlStrings=[localURL.trimmed,publicURL.trimmed].filter{!$0.isEmpty};let urls=urlStrings.compactMap(URL.init(string:))
        guard urls.count==urlStrings.count,!urls.isEmpty,urls.allSatisfy({["http","https"].contains($0.scheme ?? "") && $0.host != nil}) else{error="Enter at least one valid http:// or https:// server URL.";return}
        loading=true;error=nil
        do{await api.setBaseURLs(urls);_ = try await api.login(identifier:identifier.trimmed,password:password.trimmed);UserDefaults.standard.set(localURL.trimmed,forKey:"localServerURL");UserDefaults.standard.set(publicURL.trimmed,forKey:"publicServerURL");user=try await api.me();phase=user?.setupCompleted == false ? .setup:.signedIn;await refresh();await connectLive()}catch{self.error=error.localizedDescription};loading=false
    }
    func completeSetup(serverName:String) async {loading=true;error=nil;do{try await api.completeSetup(serverName:serverName);user=try await api.me();phase = .signedIn;await refresh()}catch{self.error=error.localizedDescription};loading=false}
    func updateConnections(localURL:String,publicURL:String) async throws {
        let strings=[localURL.trimmed,publicURL.trimmed].filter{!$0.isEmpty};let urls=strings.compactMap(URL.init(string:))
        guard urls.count==strings.count,!urls.isEmpty,urls.allSatisfy({["http","https"].contains($0.scheme ?? "") && $0.host != nil}) else{throw ConnectionSettingsError.invalidURL}
        UserDefaults.standard.set(localURL.trimmed,forKey:"localServerURL");UserDefaults.standard.set(publicURL.trimmed,forKey:"publicServerURL")
        await api.setBaseURLs(urls);await refresh();await connectLive()
    }
    func refresh() async {do{async let s=api.servers();async let h=api.health();async let a=api.alerts();async let points=api.history(start:Date().addingTimeInterval(-3600));let result=try await(s,h,a,points);server=result.0.first;healthStatus=result.1.status;metric=result.1.metrics;alerts=result.2;history=result.3}catch{healthStatus="offline";self.error=error.localizedDescription}}
    func connectLive() async {if let token=try? await api.accessToken(){let url=await api.activeBaseURL;socket.connect(baseURL:url,token:token)}}
    func logout() async {socket.disconnect();await api.logout();user=nil;phase = .signedOut}
}
enum ConnectionSettingsError:LocalizedError{case invalidURL;var errorDescription:String?{"Enter at least one valid HTTP or HTTPS server URL."}}
