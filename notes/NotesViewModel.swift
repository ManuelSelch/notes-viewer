import Foundation
import SwiftUI
import Combine

@MainActor
class NotesViewModel: ObservableObject {
    @Published var items: [GitHubItem] = []
    @Published var markdownContent: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPath: String = ""
    @Published var navigationStack: [String] = []
    
    private let service = GitHubService()
    
    let owner: String
    let repo: String
    
    init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
    }
    
    func loadContents(path: String = "") async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await service.fetchRepositoryContents(owner: owner, repo: repo, path: path)
            currentPath = path
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadFile(_ item: GitHubItem) async {
        guard item.isMarkdown else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            markdownContent = try await service.fetchFileContent(owner: owner, repo: repo, path: item.path)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func navigateToDirectory(_ item: GitHubItem) {
        guard item.isDirectory else { return }
        navigationStack.append(currentPath)
        Task {
            await loadContents(path: item.path)
        }
    }
    
    func navigateBack() {
        guard let previousPath = navigationStack.popLast() else { return }
        Task {
            await loadContents(path: previousPath)
        }
    }
    
    var canGoBack: Bool {
        !navigationStack.isEmpty
    }
}
