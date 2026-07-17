import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var showingAccount = false
    @State private var showingConnections = false
    #if PUSH_NOTIFICATIONS
    @State private var pushResult:String?
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    LabeledContent("Local", value: UserDefaults.standard.string(forKey: "localServerURL")?.nilIfEmpty ?? "Not configured")
                    LabeledContent("Public", value: UserDefaults.standard.string(forKey: "publicServerURL")?.nilIfEmpty ?? "Not configured")
                    LabeledContent("Live connection", value: app.socket.connected ? "Connected" : "Disconnected")
                    if let reason=app.socket.lastDisconnectReason { LabeledContent("Last disconnect",value:reason) }
                    Button("Change server addresses") { showingConnections = true }
                }
                Section("Account") {
                    LabeledContent("Username", value: app.user?.username ?? "—")
                    LabeledContent("Role", value: app.user?.role.capitalized ?? "—")
                    Button("Change username or password") { showingAccount = true }
                }
                Section("Application") {
                    #if PUSH_NOTIFICATIONS
                    LabeledContent("Notifications",value:app.notificationPermission)
                    #endif
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    #if PUSH_NOTIFICATIONS
                    Button("Send test notification") { Task { pushResult=await app.sendTestPush() } }
                    #endif
                    Button("Log Out", role: .destructive) { Task { await app.logout() } }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAccount) { AccountEditorView() }
            .sheet(isPresented: $showingConnections) { ConnectionEditorView() }
            #if PUSH_NOTIFICATIONS
            .alert("Test notification",isPresented:Binding(get:{pushResult != nil},set:{if !$0{pushResult=nil}})){Button("OK"){pushResult=nil}}message:{Text(pushResult ?? "")}
            #endif
        }
    }
}

struct ConnectionEditorView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var localURL = UserDefaults.standard.string(forKey: "localServerURL") ?? ""
    @State private var publicURL = UserDefaults.standard.string(forKey: "publicServerURL") ?? ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Failover addresses") {
                    TextField("Local URL", text: $localURL).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("Public URL", text: $publicURL).textInputAutocapitalization(.never).keyboardType(.URL)
                    Text("The active address is tried first. Nas Hub switches addresses only for network failures or server errors.").font(.caption).foregroundStyle(.secondary)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Connections")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(saving || (localURL.trimmed.isEmpty && publicURL.trimmed.isEmpty))
                }
            }
        }
    }

    private func save() async {
        saving = true; error = nil
        do { try await app.updateConnections(localURL: localURL, publicURL: publicURL); dismiss() }
        catch { self.error = error.localizedDescription }
        saving = false
    }
}

struct AccountEditorView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var email = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Username", text: $username).textInputAutocapitalization(.never)
                    TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                }
                Section("Password") {
                    SecureField("Current password", text: $currentPassword)
                    SecureField("New password (optional)", text: $newPassword)
                    Text("Changing the password revokes existing sessions and signs this device out.").font(.caption).foregroundStyle(.secondary)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(saving || username.trimmed.isEmpty || email.trimmed.isEmpty)
                }
            }
            .onAppear { username = app.user?.username ?? ""; email = app.user?.email ?? "" }
        }
    }

    private func save() async {
        saving = true; error = nil
        do {
            app.user = try await app.api.updateAccount(username: username.trimmed, email: email.trimmed, currentPassword: currentPassword.trimmed, newPassword: newPassword.trimmed)
            if !newPassword.trimmed.isEmpty { await app.logout() }
            dismiss()
        } catch { self.error = error.localizedDescription }
        saving = false
    }
}
