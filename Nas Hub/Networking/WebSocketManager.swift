import Foundation
@MainActor final class WebSocketManager: ObservableObject {
    @Published private(set) var connected=false; private var task:URLSessionWebSocketTask?;private var receiveTask:Task<Void,Never>?;private var attempts=0
    var onMetric:((Metric)->Void)?;var onReconnect:(()->Void)?
    func connect(baseURL:URL,token:String){disconnect();var c=URLComponents(url:baseURL, resolvingAgainstBaseURL:false);c?.scheme=baseURL.scheme=="https" ? "wss":"ws";c?.path="/ws";c?.queryItems=[URLQueryItem(name:"token",value:token)];guard let url=c?.url else{return};let socket=URLSession.shared.webSocketTask(with:url);task=socket;socket.resume();connected=true;attempts=0;socket.send(.string("{\"version\":1,\"type\":\"subscribe\",\"serverId\":\"local\"}")){_ in};receiveTask=Task{await receive()}}
    func disconnect(){receiveTask?.cancel();task?.cancel(with:.goingAway,reason:nil);task=nil;connected=false}
    private func receive()async{guard let task else{return};do{while !Task.isCancelled{let message=try await task.receive();let data:Data;switch message{case .string(let s):data=Data(s.utf8);case .data(let d):data=d;@unknown default:continue};let event=try JSONDecoder().decode(WSMessage.self,from:data);if let metric=event.data{onMetric?(metric)}}}catch{connected=false;scheduleReconnect()}}
    private func scheduleReconnect(){attempts+=1;let delay=min(pow(2.0,Double(attempts)),30);Task{try? await Task.sleep(for:.seconds(delay));guard !Task.isCancelled else{return};onReconnect?()}}
}

