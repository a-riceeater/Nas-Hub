import SwiftUI
import Charts

private struct TileFramePreferenceKey:PreferenceKey{
    static var defaultValue:[DashboardTile:CGRect]=[:]
    static func reduce(value:inout [DashboardTile:CGRect],nextValue:()->[DashboardTile:CGRect]){value.merge(nextValue(),uniquingKeysWith:{$1})}
}

struct DashboardView: View {
    @EnvironmentObject var app:AppState
    @StateObject private var tileStore=DashboardTileStore()
    @State private var editingTiles=false
    @State private var draggedTile:DashboardTile?
    @State private var dragLocation:CGPoint = .zero
    @State private var tileFrames:[DashboardTile:CGRect]=[:]
    private let columns=[GridItem(.flexible()),GridItem(.flexible())]

    var body:some View{
        NavigationStack{ScrollView{VStack(alignment:.leading,spacing:18){
            header
            if editingTiles { HStack{Label("Drag tiles to reorder; tap − to remove",systemImage:"hand.draw");Spacer();Button("Done"){finishEditing()}}.font(.caption).foregroundStyle(.secondary) }
            if let metric=app.metric {
                tileGrid(metric)
                chart(metric)
            } else { ContentUnavailableView("Waiting for metrics",systemImage:"waveform.path.ecg",description:Text("Live data will appear after the server responds.")) }
        }.padding()}.refreshable{await app.refresh()}.navigationTitle("Dashboard")}
    }

    private func tileGrid(_ metric:Metric)->some View{
        ZStack(alignment:.topLeading){
            LazyVGrid(columns:columns,spacing:12){ForEach(tileStore.tiles){tile in tileView(tile,metric:metric)}}
            if let tile=draggedTile,let frame=tileFrames[tile]{
                tile.view(metric:metric)
                    .frame(width:frame.width,height:frame.height)
                    .scaleEffect(1.06)
                    .shadow(color:.black.opacity(0.28),radius:18,y:8)
                    .position(dragLocation)
                    .allowsHitTesting(false)
                    .zIndex(100)
            }
        }
        .coordinateSpace(name:"tileGrid")
        .onPreferenceChange(TileFramePreferenceKey.self){tileFrames=$0}
    }

    private func tileView(_ tile:DashboardTile,metric:Metric)->some View{
        tile.view(metric:metric)
            .background(GeometryReader{proxy in Color.clear.preference(key:TileFramePreferenceKey.self,value:[tile:proxy.frame(in:.named("tileGrid"))])})
            .overlay(alignment:.topTrailing){if editingTiles{Button{withAnimation{tileStore.remove(tile)}}label:{Image(systemName:"minus.circle.fill").font(.title2).foregroundStyle(.red).background(.white,in:Circle())}.offset(x:6,y:-6).zIndex(2)}}
            .contentShape(RoundedRectangle(cornerRadius:18))
            .onLongPressGesture(minimumDuration:0.45){withAnimation(.spring(response:0.25)){editingTiles=true}}
            .gesture(dragGesture(for:tile),including:editingTiles ? .all:.none)
            .opacity(draggedTile==tile ? 0:editingTiles ? 0.94:1)
            .animation(.spring(response:0.28,dampingFraction:0.82),value:tileStore.tiles)
    }

    private func dragGesture(for tile:DashboardTile)->some Gesture{
        DragGesture(minimumDistance:2,coordinateSpace:.named("tileGrid"))
            .onChanged{value in
                guard editingTiles else{return}
                if draggedTile==nil{draggedTile=tile;dragLocation=tileFrames[tile]?.center ?? value.location}
                guard draggedTile==tile else{return}
                dragLocation=value.location
                let candidates=tileFrames.filter{$0.key != tile}
                if let target=candidates.min(by:{$0.value.center.distance(to:value.location) < $1.value.center.distance(to:value.location)})?.key,
                   let targetFrame=tileFrames[target],targetFrame.insetBy(dx:-12,dy:-12).contains(value.location){
                    withAnimation(.spring(response:0.25,dampingFraction:0.8)){tileStore.move(tile,to:target)}
                }
            }
            .onEnded{_ in withAnimation(.spring(response:0.3,dampingFraction:0.8)){draggedTile=nil}}
    }

    private func finishEditing(){withAnimation{draggedTile=nil;editingTiles=false}}

    private var header:some View{HStack(alignment:.top){VStack(alignment:.leading,spacing:3){Text(app.server?.name ?? "Local server").font(.title2.bold());Text("Public IPv4: \(app.metric?.publicIPv4 ?? "Unavailable")").font(.caption.monospaced()).foregroundStyle(.secondary);HStack{Circle().fill(statusColor).frame(width:9,height:9);Text(statusLabel);if let m=app.metric{Text("• Updated \(Date(timeIntervalSince1970:m.timestamp/1000),style:.relative)")}}.font(.caption).foregroundStyle(.secondary)};Spacer();if let m=app.metric{Text(Units.duration(m.uptime)).font(.callout.monospacedDigit())}}}
    private func chart(_ m:Metric)->some View{VStack(alignment:.leading){HStack{Text("CPU — Last hour").font(.headline);Spacer();Text(Units.percent(m.cpuPercent)).monospacedDigit()};Chart(app.history){point in LineMark(x:.value("Time",Date(timeIntervalSince1970:point.timestamp/1000)),y:.value("CPU",point.cpuPercent ?? 0)).foregroundStyle(.cyan).interpolationMethod(.catmullRom);AreaMark(x:.value("Time",Date(timeIntervalSince1970:point.timestamp/1000)),y:.value("CPU",point.cpuPercent ?? 0)).foregroundStyle(.linearGradient(colors:[.cyan.opacity(0.3),.clear],startPoint:.top,endPoint:.bottom))}.chartYScale(domain:0...100).frame(height:210)}.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18))}
    private var statusLabel:String{app.healthStatus=="connecting" ? "Connecting…":app.healthStatus.capitalized}
    private var statusColor:Color{app.healthStatus=="critical" ? .red:app.healthStatus=="warning" ? .orange:app.healthStatus=="healthy" ? .green:.gray}
}

private extension CGRect{var center:CGPoint{CGPoint(x:midX,y:midY)}}
private extension CGPoint{func distance(to other:CGPoint)->CGFloat{hypot(x-other.x,y-other.y)}}
