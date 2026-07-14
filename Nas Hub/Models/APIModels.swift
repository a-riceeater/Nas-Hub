import Foundation

struct APIEnvelope<T: Decodable>: Decodable { let data: T }
struct Tokens: Codable { let accessToken: String; let refreshToken: String; let expiresIn: Int }
struct User: Codable { let id: String; let username: String; let email: String; let role: String; let setupCompleted: Bool }
struct Server: Codable, Identifiable { let id: String; let name: String; let hostname: String; let lastSeenAt: Double? }
struct Metric: Codable, Identifiable {
    var id: Double { timestamp }; let timestamp: Double; let cpuPercent: Double?; let perCore: [Double]?
    let load1, load5, load15: Double; let ramTotal, ramUsed, ramAvailable: Double; let ramPercent: Double
    let swapTotal, swapUsed, diskTotal, diskUsed, diskAvailable: Double; let diskPercent: Double?
    let diskReadBps, diskWriteBps, networkRxBps, networkTxBps: Double?; let uptime: Double
    let processCount: Int; let temperature: Double?; let bootTime: Double
}
struct Health: Codable { let serverId, status: String; let activeAlertCount: Int; let lastUpdated: Double?; let metrics: Metric? }
struct AlertItem: Codable, Identifiable { let id, serverId, ruleId, severity, status, title, message: String; let metricValue, thresholdValue: Double?; let triggeredAt: Double; let acknowledgedAt, resolvedAt: Double? }
struct WSMessage: Decodable { let version: Int; let type: String; let timestamp, serverId: String?; let data: Metric? }
