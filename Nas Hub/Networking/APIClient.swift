import Foundation

actor APIClient {
    private(set) var baseURL: URL; private let store: TokenStore; private let session: URLSession
    init(baseURL: URL, store: TokenStore, session: URLSession = .shared) { self.baseURL=baseURL;self.store=store;self.session=session }
    func setBaseURL(_ url: URL){baseURL=url}
    func login(identifier:String,password:String) async throws -> Tokens { let payload=["identifier":identifier,"password":password,"deviceDescription":"iPhone"];let tokens:Tokens=try await send("api/v1/auth/login",method:"POST",body:payload,authenticated:false);try store.save(tokens);return tokens }
    func me() async throws -> User { try await send("api/v1/auth/me") }
    func servers() async throws -> [Server] { try await send("api/v1/servers") }
    func health() async throws -> Health { try await send("api/v1/servers/local/health") }
    func history(start:Date,maxPoints:Int=300) async throws -> [Metric] { try await send("api/v1/servers/local/metrics/history?start=\(Int(start.timeIntervalSince1970*1000))&maxPoints=\(maxPoints)") }
    func alerts() async throws -> [AlertItem] { try await send("api/v1/alerts") }
    func acknowledge(_ id:String) async throws { let _:Ack=try await send("api/v1/alerts/\(id)/acknowledge",method:"POST",body:[String:String]()); }
    func testPush() async throws { let _:Ack=try await send("api/v1/push/test",method:"POST",body:[String:String]()) }
    func logout() async { if let token=try? store.load()?.refreshToken { let _:Ack?=try? await send("api/v1/auth/logout",method:"POST",body:["refreshToken":token],authenticated:false) };try? store.clear() }
    func accessToken() throws -> String? { try store.load()?.accessToken }
    private func refresh() async throws { guard let old=try store.load() else{throw APIError.unauthorized};let fresh:Tokens=try await send("api/v1/auth/refresh",method:"POST",body:["refreshToken":old.refreshToken],authenticated:false,retry:false);try store.save(fresh) }
    private func send<T:Decodable,B:Encodable>(_ path:String,method:String="GET",body:B?=Optional<String>.none,authenticated:Bool=true,retry:Bool=true) async throws -> T { var req=URLRequest(url:baseURL.appending(path:path));req.httpMethod=method;req.setValue("application/json",forHTTPHeaderField:"Content-Type");if let body{req.httpBody=try JSONEncoder().encode(body)};if authenticated,let token=try store.load()?.accessToken{req.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization")};let(data,response)=try await session.data(for:req);guard let http=response as? HTTPURLResponse else{throw APIError.invalidResponse};if http.statusCode==401&&authenticated&&retry{try await refresh();return try await send(path,method:method,body:body,authenticated:true,retry:false)};guard 200..<300 ~= http.statusCode else{throw APIError.server(http.statusCode)};if http.statusCode==204{return Ack(acknowledged:true) as! T};return try JSONDecoder().decode(APIEnvelope<T>.self,from:data).data }
}
private struct Ack:Codable{let acknowledged:Bool};enum APIError:LocalizedError{case invalidResponse,unauthorized,server(Int);var errorDescription:String?{switch self{case .invalidResponse:return"Invalid server response";case .unauthorized:return"Please sign in again";case .server(let code):return"Server error (\(code))"}}}

