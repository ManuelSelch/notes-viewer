import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    var isInitialSetup: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var rootFolders: [GitHubItem] = []
    @State private var isLoadingFolders = false
    
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
                
                if settings.isConfigured {
                    Section("Favorites") {
                        if isLoadingFolders {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if rootFolders.isEmpty {
                            Text("No folders found")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(rootFolders) { folder in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(folder.name)
                                    Spacer()
                                    Button {
                                        settings.toggleFavorite(path: folder.path)
                                    } label: {
                                        Image(systemName: settings.isFavorite(path: folder.path) ? "star.fill" : "star")
                                            .foregroundColor(settings.isFavorite(path: folder.path) ? .yellow : .gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
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
            .task {
                await loadRootFolders()
            }
            .onChange(of: settings.owner) { _, _ in
                Task { await loadRootFolders() }
            }
            .onChange(of: settings.repo) { _, _ in
                Task { await loadRootFolders() }
            }
        }
    }
    
    private func loadRootFolders() async {
        guard settings.isConfigured else { return }
        isLoadingFolders = true
        
        let service = GitHubService(token: settings.token)
        do {
            let items = try await service.fetchRepositoryContents(
                owner: settings.owner,
                repo: settings.repo,
                path: ""
            )
            rootFolders = items.filter { $0.isDirectory }
        } catch {
            rootFolders = []
        }
        
        isLoadingFolders = false
    }
}

#Preview {
    SettingsView(settings: SettingsStore())
}
