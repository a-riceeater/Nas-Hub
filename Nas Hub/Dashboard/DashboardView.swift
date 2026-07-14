import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var app:AppState
    @StateObject private var tileStore=DashboardTileStore()
    @State private var editingTiles=false
    private let columns=[GridItem(.flexible()),GridItem(.flexible())]

    var body:some View{
        NavigationStack{ScrollView{VStack(alignment:.leading,spacing:18){
            header
            if editingTiles { HStack{Label("Drag tiles to reorder; tap − to remove",systemImage:"hand.draw");Spacer();Button("Done"){withAnimation{editingTiles=false}}}.font(.caption).foregroundStyle(.secondary) }
            if let metric=app.metric {
                LazyVGrid(columns:columns,spacing:12){
                    ForEach(tileStore.tiles){tile in tileView(tile,metric:metric)}
                }
                chart(metric)
            } else { ContentUnavailableView("Waiting for metrics",systemImage:"waveform.path.ecg",description:Text("Live data will appear after the server responds.")) }
        }.padding()}.refreshable{await app.refresh()}.navigationTitle("Dashboard")}
    }

    private func tileView(_ tile:DashboardTile,metric:Metric)->some View{
        tile.view(metric:metric)
            .overlay(alignment:.topTrailing){if editingTiles{Button{withAnimation{tileStore.remove(tile)}}label:{Image(systemName:"minus.circle.fill").font(.title2).foregroundStyle(.red).background(.white,in:Circle())}.offset(x:6,y:-6)}}
            .contentShape(RoundedRectangle(cornerRadius:18))
            .onLongPressGesture(minimumDuration:0.45){withAnimation{editingTiles=true}}
            .draggable(tile.rawValue)
            .dropDestination(for:String.self){items,_ in guard editingTiles,let raw=items.first,let source=DashboardTile(rawValue:raw)else{return false};withAnimation{tileStore.move(source,before:tile)};return true}
            .opacity(editingTiles ? 0.94:1)
    }

    private var header:some View{HStack{VStack(alignment:.leading){Text(app.server?.name ?? "Local server").font(.title2.bold());HStack{Circle().fill(statusColor).frame(width:9,height:9);Text(statusLabel);if let m=app.metric{Text("• Updated \(Date(timeIntervalSince1970:m.timestamp/1000),style:.relative)")}}.font(.caption).foregroundStyle(.secondary)};Spacer();if let m=app.metric{Text(Units.duration(m.uptime)).font(.callout.monospacedDigit())}}}
    private func chart(_ m:Metric)->some View{VStack(alignment:.leading){HStack{Text("CPU — Last hour").font(.headline);Spacer();Text(Units.percent(m.cpuPercent)).monospacedDigit()};Chart(app.history){point in LineMark(x:.value("Time",Date(timeIntervalSince1970:point.timestamp/1000)),y:.value("CPU",point.cpuPercent ?? 0)).foregroundStyle(.cyan).interpolationMethod(.catmullRom);AreaMark(x:.value("Time",Date(timeIntervalSince1970:point.timestamp/1000)),y:.value("CPU",point.cpuPercent ?? 0)).foregroundStyle(.linearGradient(colors:[.cyan.opacity(0.3),.clear],startPoint:.top,endPoint:.bottom))}.chartYScale(domain:0...100).frame(height:210)}.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18))}
    private var statusLabel:String{app.healthStatus=="connecting" ? "Connecting…":app.healthStatus.capitalized}
    private var statusColor:Color{app.healthStatus=="critical" ? .red:app.healthStatus=="warning" ? .orange:app.healthStatus=="healthy" ? .green:.gray}
}
