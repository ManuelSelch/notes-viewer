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
                    ProgressView()
                        .scaleEffect(1.2)
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
        .task {
            await viewModel.load(owner: owner, repo: repo, token: token, path: item.path)
        }
    }
}

@MainActor
class DetailViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private let service = GitHubService()
    
    func load(owner: String, repo: String, token: String, path: String) async {
        isLoading = true
        error = nil
        
        let authenticatedService = GitHubService(token: token)
        
        do {
            content = try await authenticatedService.fetchFileContent(owner: owner, repo: repo, path: path)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(
            owner: "ManuelSelch",
            repo: "pi-memory-md",
            token: "",
            item: GitHubItem(
                name: "README.md",
                path: "README.md",
                sha: "abc",
                size: 100,
                url: "",
                htmlUrl: "",
                gitUrl: "",
                downloadUrl: nil,
                type: "file"
            )
        )
    }
}
