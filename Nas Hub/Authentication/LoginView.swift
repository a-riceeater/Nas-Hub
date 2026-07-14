import SwiftUI

struct LoginView: View {
    @EnvironmentObject var app: AppState
    @State private var localURL=UserDefaults.standard.string(forKey:"localServerURL") ?? "http://localhost:3232"
    @State private var publicURL=UserDefaults.standard.string(forKey:"publicServerURL") ?? ""
    @State private var identifier="";@State private var password=""
    var body: some View {
        NavigationStack { ScrollView { VStack(spacing:22) {
            Image(systemName:"server.rack").font(.system(size:54)).foregroundStyle(.cyan)
            VStack(spacing:5){Text("Nas Hub").font(.largeTitle.bold());Text("Your server, at a glance").foregroundStyle(.secondary)}
            VStack(spacing:14){
                TextField("Local server URL",text:$localURL).textInputAutocapitalization(.never).keyboardType(.URL).textContentType(.URL)
                TextField("Public server URL (optional)",text:$publicURL).textInputAutocapitalization(.never).keyboardType(.URL).textContentType(.URL)
                TextField("Username or email",text:$identifier).textInputAutocapitalization(.never).textContentType(.username)
                SecureField("Password",text:$password).textContentType(.password)
            }.textFieldStyle(.roundedBorder)
            if let error=app.error{Text(error).foregroundStyle(.red).font(.callout)}
            Button{Task{await app.login(localURL:localURL.trimmed,publicURL:publicURL.trimmed,identifier:identifier.trimmed,password:password.trimmed)}} label:{Group{if app.loading{ProgressView()}else{Text("Sign In").bold()}}.frame(maxWidth:.infinity).padding(.vertical,6)}.buttonStyle(.borderedProminent).disabled(app.loading||identifier.trimmed.isEmpty||password.trimmed.isEmpty||(localURL.trimmed.isEmpty&&publicURL.trimmed.isEmpty))
            Text("Nas Hub tries the active address first and automatically fails over on connection or server failures. Production addresses must use HTTPS/WSS.").font(.caption).foregroundStyle(.secondary)
        }.padding(28).frame(maxWidth:520) }.navigationTitle("Sign in") }
    }
}
