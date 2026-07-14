import SwiftUI

struct SetupView: View {
    @EnvironmentObject var app: AppState
    @State private var serverName="Home Server"
    var body: some View {
        NavigationStack { VStack(spacing:24) {
            Spacer();Image(systemName:"checkmark.shield.fill").font(.system(size:58)).foregroundStyle(.cyan)
            Text("Welcome to Nas Hub").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Give this server a friendly name. You can change your account and connection addresses later in Settings.").foregroundStyle(.secondary).multilineTextAlignment(.center)
            TextField("Server name",text:$serverName).textFieldStyle(.roundedBorder).textInputAutocapitalization(.words)
            if let error=app.error{Text(error).foregroundStyle(.red).font(.callout)}
            Button{Task{await app.completeSetup(serverName:serverName.trimmed)}} label:{Group{if app.loading{ProgressView()}else{Text("Finish Setup").bold()}}.frame(maxWidth:.infinity)}.buttonStyle(.borderedProminent).disabled(serverName.trimmed.isEmpty||app.loading)
            Spacer()
        }.padding(30).frame(maxWidth:520).navigationTitle("First-time setup") }
    }
}
