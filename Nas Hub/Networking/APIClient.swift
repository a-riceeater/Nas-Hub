import Foundation

actor APIClient {
    private(set) var baseURLs: [URL]
    private(set) var activeBaseURL: URL
    private let store: TokenStore
    private let session: URLSession

    init(baseURLs: [URL], store: TokenStore, session: URLSession = .shared) {
        let fallback = URL(string: "http://localhost:3000")!
        self.baseURLs = baseURLs.isEmpty ? [fallback] : baseURLs
        self.activeBaseURL = baseURLs.first ?? fallback
        self.store = store
        self.session = session
    }

    func setBaseURLs(_ urls: [URL]) {
        baseURLs = urls
        if !urls.contains(activeBaseURL), let first = urls.first { activeBaseURL = first }
    }

    func login(identifier: String, password: String) async throws -> Tokens {
        let payload = ["identifier": identifier.trimmed, "password": password.trimmed, "deviceDescription": "iPhone"]
        let tokens: Tokens = try await send("api/v1/auth/login", method: "POST", body: payload, authenticated: false)
        try store.save(tokens)
        return tokens
    }
    func me() async throws -> User { try await send("api/v1/auth/me") }
    func updateAccount(username: String, email: String, currentPassword: String?, newPassword: String?) async throws -> User {
        try await send("api/v1/auth/me", method: "PATCH", body: AccountUpdate(username: username.trimmed, email: email.trimmed, currentPassword: currentPassword?.trimmed.nilIfEmpty, newPassword: newPassword?.trimmed.nilIfEmpty))
    }
    func completeSetup(serverName: String) async throws { let _: Ack = try await send("api/v1/setup", method: "POST", body: ["serverName": serverName.trimmed]) }
    func servers() async throws -> [Server] { try await send("api/v1/servers") }
    func health() async throws -> Health { try await send("api/v1/servers/local/health") }
    func history(start: Date, maxPoints: Int = 300) async throws -> [Metric] { try await send("api/v1/servers/local/metrics/history?start=\(Int(start.timeIntervalSince1970*1000))&maxPoints=\(maxPoints)") }
    func alerts() async throws -> [AlertItem] { try await send("api/v1/alerts") }
    func acknowledge(_ id: String) async throws { let _: Ack = try await send("api/v1/alerts/\(id)/acknowledge", method: "POST", body: [String:String]()) }
    #if PUSH_NOTIFICATIONS
    func testPush() async throws -> PushTestResult { try await send("api/v1/push/test", method: "POST", body: [String:String]()) }
    func registerPushToken(_ token:String) async throws {let _:DeviceRegistration=try await send("api/v1/push/devices",method:"POST",body:PushRegistration(token:token,environment:apnsEnvironment,topic:Bundle.main.bundleIdentifier ?? "com.ebantugan.Nas-Hub",deviceName:"iPhone"))}
    #endif
    func logout() async { if let token = try? store.load()?.refreshToken { let _: Ack? = try? await send("api/v1/auth/logout", method: "POST", body: ["refreshToken":token], authenticated:false) }; try? store.clear() }
    func accessToken() throws -> String? { try store.load()?.accessToken }

    private func refresh() async throws {
        guard let old=try store.load() else { throw APIError.unauthorized }
        let fresh: Tokens = try await send("api/v1/auth/refresh",method:"POST",body:["refreshToken":old.refreshToken],authenticated:false,retry:false)
        try store.save(fresh)
    }

    private func send<T: Decodable, B: Encodable>(_ path: String, method: String = "GET", body: B? = Optional<String>.none, authenticated: Bool = true, retry: Bool = true) async throws -> T {
        let candidates = [activeBaseURL] + baseURLs.filter { $0 != activeBaseURL }
        var lastError: Error = APIError.unreachable
        for candidate in candidates {
            do {
                let value: T = try await sendOnce(path, method: method, body: body, authenticated: authenticated, baseURL: candidate)
                activeBaseURL = candidate
                return value
            } catch APIError.unauthorized where authenticated && retry {
                try await refresh()
                return try await send(path, method: method, body: body, authenticated: true, retry: false)
            } catch APIError.server(let status, _) where status >= 500 {
                lastError = APIError.server(status, "Server unavailable")
            } catch let error as URLError {
                lastError = error
            } catch {
                throw error
            }
        }
        throw lastError
    }

    private func sendOnce<T: Decodable, B: Encodable>(_ path: String, method: String, body: B?, authenticated: Bool, baseURL: URL) async throws -> T {
        var request=URLRequest(url:baseURL.appending(path:path)); request.httpMethod=method; request.timeoutInterval=8
        request.setValue("application/json",forHTTPHeaderField:"Content-Type")
        if let body { request.httpBody=try JSONEncoder().encode(body) }
        if authenticated,let token=try store.load()?.accessToken { request.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization") }
        let(data,response)=try await session.data(for:request)
        guard let http=response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard 200..<300 ~= http.statusCode else { let message=(try? JSONDecoder().decode(APIErrorEnvelope.self,from:data).error.message) ?? "Server error"; throw APIError.server(http.statusCode,message) }
        if http.statusCode == 204 { return Ack(acknowledged:true) as! T }
        return try JSONDecoder().decode(APIEnvelope<T>.self,from:data).data
    }
}

private struct AccountUpdate: Encodable { let username,email:String;let currentPassword,newPassword:String? }
#if PUSH_NOTIFICATIONS
private struct PushRegistration:Encodable{let token,environment,topic,deviceName:String}
private struct DeviceRegistration:Decodable{let id:String}
struct PushTestResult:Decodable{let acknowledged:Bool;let sent,failed:Int;let provider:String}
#if DEBUG
private let apnsEnvironment="development"
#else
private let apnsEnvironment="production"
#endif
#endif
private struct Ack: Codable { let acknowledged: Bool }
private struct APIErrorEnvelope: Decodable { struct Detail:Decodable{let message:String};let error:Detail }
enum APIError: LocalizedError { case invalidResponse,unauthorized,unreachable,server(Int,String);var errorDescription:String?{switch self{case .invalidResponse:return"Invalid server response";case .unauthorized:return"Please sign in again";case .unreachable:return"Neither server address could be reached";case .server(_,let message):return message}} }
extension String { var trimmed:String{trimmingCharacters(in:.whitespacesAndNewlines)};var nilIfEmpty:String?{isEmpty ? nil:self} }
