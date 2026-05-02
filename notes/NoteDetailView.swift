import SwiftUI
import Combine
import Textual

struct NoteDetailView: View {
    let owner: String
    let repo: String
    let token: String
    let item: GitHubItem
    
    @StateObject private var viewModel = DetailViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.2)
                    Text("Loading…")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                StructuredText(
                    markdown: viewModel.content,
                    syntaxExtensions: [.math]
                )
                .padding()
            }
        }
        .navigationTitle(item.jdInfo.title)
        .toolbar {
            if viewModel.isOffline {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                }
            }
        }
        .task {
            await viewModel.load(owner: owner, repo: repo, token: token, path: item.path)
        }
    }
}

@MainActor
class DetailViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var isLoading = false
    @Published var isOffline = false
    @Published var error: String?
    
    private let cache = OfflineCache.shared
    
    func load(owner: String, repo: String, token: String, path: String) async {
        isLoading = true
        error = nil
        isOffline = false
        
        // Offline cache first
        if let cached = await cache.file(for: path) {
            content = cached
            isOffline = true
        }
        
        // Net check
        guard await canReachGitHub() else {
            content = await cache.file(for: path) ?? content
            isLoading = false
            return
        }
        
        let service = GitHubService(token: token)
        do {
            let freshContent = try await service.fetchFileContent(owner: owner, repo: repo, path: path)
            content = freshContent
            isOffline = false
            await cache.setFile(content: freshContent, for: path)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            if content.isEmpty {
                self.error = "No network — file not cached"
            }
            isOffline = true
        } catch {
            if content.isEmpty {
                self.error = error.localizedDescription
            } else {
                isOffline = true
                self.error = "Offline — showing cached content"
            }
        }
        
        isLoading = false
    }
    
    private func canReachGitHub() async -> Bool {
        var request = URLRequest(url: URL(string: "https://api.github.com")!)
        request.timeoutInterval = 3
        do {
            _ = try await URLSession.shared.data(for: request)
            return true
        } catch {
            return false
        }
    }
}
