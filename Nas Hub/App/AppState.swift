import Foundation
@MainActor final class AppState:ObservableObject{
 enum Phase{case restoring,signedOut,signedIn}
 @Published var phase:Phase = .restoring;@Published var user:User?;@Published var server:Server?;@Published var metric:Metric?;@Published var history:[Metric]=[];@Published var alerts:[AlertItem]=[];@Published var healthStatus="unknown";@Published var error:String?;@Published var loading=false
 let socket=WebSocketManager();let store:TokenStore;let api:APIClient
 init(){let store=KeychainStore();self.store=store;let text=UserDefaults.standard.string(forKey:"serverURL") ?? "http://localhost:3000";self.api=APIClient(baseURL:URL(string:text) ?? URL(string:"http://localhost:3000")!,store:store);socket.onMetric={ [weak self] m in self?.metric=m;self?.history.append(m);if let count=self?.history.count,count>300{self?.history.removeFirst(count-300)}};socket.onReconnect={ [weak self] in Task{await self?.connectLive();await self?.refresh()} };Task{await restore()}}
 func restore()async{guard (try? store.load()) != nil else{phase = .signedOut;return};do{user=try await api.me();phase = .signedIn;await refresh();await connectLive()}catch{try? store.clear();phase = .signedOut}}
 func login(url:String,identifier:String,password:String)async{guard let parsed=URL(string:url),let scheme=parsed.scheme,["http","https"].contains(scheme),parsed.host != nil else{error="Enter a valid http:// or https:// server URL.";return};loading=true;error=nil;do{await api.setBaseURL(parsed);_ = try await api.login(identifier:identifier,password:password);UserDefaults.standard.set(url,forKey:"serverURL");user=try await api.me();phase = .signedIn;await refresh();await connectLive()}catch{self.error=error.localizedDescription};loading=false}
 func refresh()async{do{async let s=api.servers();async let h=api.health();async let a=api.alerts();async let points=api.history(start:Date().addingTimeInterval(-3600));let result=try await(s,h,a,points);server=result.0.first;healthStatus=result.1.status;metric=result.1.metrics;alerts=result.2;history=result.3}catch{self.error=error.localizedDescription}}
 func connectLive()async{if let token = try? await api.accessToken(),let text=UserDefaults.standard.string(forKey:"serverURL"),let url=URL(string:text){socket.connect(baseURL:url,token:token)}}
 func logout()async{socket.disconnect();await api.logout();user=nil;phase = .signedOut}
}
