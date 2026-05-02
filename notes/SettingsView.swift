import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    var isInitialSetup: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Repository") {
                    TextField("Owner (e.g. ManuelSelch)", text: $settings.owner)
                    TextField("Repository name (e.g. pi-memory-md)", text: $settings.repo)
                }
                
                Section("Authentication") {
                    SecureField("GitHub Token (optional)", text: $settings.token)
                    Text("Required only for private repos. Generate at github.com/settings/tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isInitialSetup {
                    Section {
                        Button("Continue") {
                            // Dismiss is handled by parent re-evaluating isConfigured
                        }
                        .disabled(!settings.isConfigured)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                if !isInitialSetup {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settings: SettingsStore())
}
