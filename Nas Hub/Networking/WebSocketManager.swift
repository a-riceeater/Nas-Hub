import Foundation

@MainActor final class WebSocketManager: ObservableObject {
    @Published private(set) var connected = false
    @Published private(set) var lastDisconnectReason: String?
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var generation = UUID()
    private var attempts = 0
    var onMetric: ((Metric) -> Void)?
    var onReconnect: (() -> Void)?

    func connect(baseURL: URL, token: String) {
        stopSocket(scheduleReconnect: false)
        let connectionID = UUID(); generation = connectionID
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components?.path = "/ws"
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components?.url else { return }

        let socket = URLSession.shared.webSocketTask(with: url)
        task = socket; socket.resume()
        socket.send(.string("{\"version\":1,\"type\":\"subscribe\",\"serverId\":\"local\"}")) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.transportFailed(error, socket: socket, connectionID: connectionID) }
        }
        connected = true; attempts = 0; lastDisconnectReason = nil
        reconnectTask?.cancel(); reconnectTask = nil
        receiveTask = Task { [weak self] in await self?.receive(socket: socket, connectionID: connectionID) }
    }

    func disconnect() { stopSocket(scheduleReconnect: false) }

    private func receive(socket: URLSessionWebSocketTask, connectionID: UUID) async {
        do {
            while !Task.isCancelled {
                let message = try await socket.receive()
                let data: Data
                switch message { case .string(let string): data=Data(string.utf8);case .data(let value):data=value;@unknown default:continue }
                do {
                    let event=try JSONDecoder().decode(WSMessage.self,from:data)
                    if let metric=event.data { onMetric?(metric) }
                } catch {
                    // A new protocol message must not be mistaken for transport failure.
                    print("Nas Hub ignored WebSocket message that could not be decoded: \(error.localizedDescription)")
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            transportFailed(error, socket: socket, connectionID: connectionID)
        }
    }

    private func transportFailed(_ error: Error, socket: URLSessionWebSocketTask, connectionID: UUID) {
        guard generation == connectionID, task === socket else { return }
        let closeCode=socket.closeCode.rawValue
        let reason=socket.closeReason.flatMap{String(data:$0,encoding:.utf8)} ?? error.localizedDescription
        lastDisconnectReason="Code \(closeCode): \(reason)"
        print("Nas Hub WebSocket disconnected (\(lastDisconnectReason ?? "unknown"))")
        stopSocket(scheduleReconnect:true)
    }

    private func stopSocket(scheduleReconnect shouldReconnect: Bool) {
        let oldTask=task
        generation=UUID();task=nil;connected=false
        receiveTask?.cancel();receiveTask=nil
        oldTask?.cancel(with:.goingAway,reason:nil)
        if shouldReconnect { scheduleReconnect() } else { reconnectTask?.cancel();reconnectTask=nil }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel();attempts += 1
        let delay=min(pow(2.0,Double(attempts)),30)
        reconnectTask=Task { [weak self] in
            do { try await Task.sleep(for:.seconds(delay)) } catch { return }
            guard !Task.isCancelled else { return }
            self?.onReconnect?()
        }
    }
}
