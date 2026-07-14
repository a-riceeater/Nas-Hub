import SwiftUI

enum DashboardTile: String, Codable, CaseIterable, Identifiable {
    case cpu, system, memory, diskTotal, diskUtilization, networkDown, networkUp, swap, publicIPv4
    var id:String{rawValue}
    static let defaults:[DashboardTile]=[.cpu,.system,.memory,.diskUtilization,.diskTotal,.networkDown,.networkUp,.swap,.publicIPv4]

    @ViewBuilder func view(metric:Metric)->some View {
        switch self {
        case .cpu: MetricCard(title:"CPU",value:Units.percent(metric.cpuPercent),detail:String(format:"Load %.2f",metric.load1),icon:"cpu",tint:usageColor(metric.cpuPercent))
        case .system: MetricCard(title:"System utilization",value:Units.percent(metric.systemUtilization),detail:"1m load across \(metric.perCore?.count ?? 0) cores",icon:"gauge.with.dots.needle.50percent",tint:usageColor(metric.systemUtilization))
        case .memory: MetricCard(title:"Memory",value:Units.percent(metric.ramPercent),detail:"\(Units.bytes(metric.ramUsed)) of \(Units.bytes(metric.ramTotal))",icon:"memorychip",tint:usageColor(metric.ramPercent))
        case .diskTotal: MetricCard(title:"Disk total",value:Units.bytes(metric.diskTotal),detail:"\(Units.bytes(metric.diskUsed)) used",icon:"internaldrive",tint:.blue)
        case .diskUtilization: MetricCard(title:"Disk utilization",value:Units.percent(metric.diskPercent),detail:"\(Units.bytes(metric.diskAvailable)) free",icon:"chart.pie.fill",tint:usageColor(metric.diskPercent))
        case .networkDown: MetricCard(title:"Download",value:Units.rate(metric.networkRxBps),detail:"Network receive",icon:"arrow.down",tint:.cyan)
        case .networkUp: MetricCard(title:"Upload",value:Units.rate(metric.networkTxBps),detail:"Network transmit",icon:"arrow.up",tint:.indigo)
        case .swap: MetricCard(title:"Swap",value:Units.bytes(metric.swapUsed),detail:"of \(Units.bytes(metric.swapTotal))",icon:"arrow.triangle.2.circlepath",tint:usageColor(metric.swapTotal > 0 ? metric.swapUsed/metric.swapTotal*100:nil))
        case .publicIPv4: MetricCard(title:"Public IPv4",value:metric.publicIPv4 ?? "Unavailable",detail:"Refreshed periodically",icon:"globe.americas.fill",tint:.mint)
        }
    }
    private func usageColor(_ value:Double?)->Color{guard let value else{return.secondary};return value>=90 ? .red:value>=75 ? .orange:.green}
}

@MainActor final class DashboardTileStore:ObservableObject{
    @Published var tiles:[DashboardTile]{didSet{UserDefaults.standard.set(tiles.map(\.rawValue),forKey:"dashboardTiles")}}
    init(){let saved=UserDefaults.standard.stringArray(forKey:"dashboardTiles")?.compactMap(DashboardTile.init(rawValue:));tiles=saved ?? DashboardTile.defaults}
    func remove(_ tile:DashboardTile){tiles.removeAll{$0==tile}}
    func move(_ source:DashboardTile,before target:DashboardTile){guard source != target,let from=tiles.firstIndex(of:source),let to=tiles.firstIndex(of:target)else{return};let item=tiles.remove(at:from);let adjusted=from<to ? to-1:to;tiles.insert(item,at:max(0,adjusted))}
}
