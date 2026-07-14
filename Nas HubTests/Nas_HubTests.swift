import Testing
@testable import Nas_Hub
struct Nas_HubTests {
    @Test func unitFormatting() { #expect(Units.percent(81.4) == "81%"); #expect(Units.percent(nil) == "—"); #expect(Units.duration(90) == "0h 1m") }
    @Test func websocketDecoding() throws { let json=#"{"version":1,"type":"pong","timestamp":"2026-07-13T20:00:00Z"}"#.data(using:.utf8)!; let value=try JSONDecoder().decode(WSMessage.self,from:json);#expect(value.version == 1);#expect(value.type == "pong") }
}
