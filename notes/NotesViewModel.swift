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
    
    let settings: SettingsStore
    private let service: GitHubService
    
    init(settings: SettingsStore) {
        self.settings = settings
        self.service = GitHubService(token: settings.token)
    }
    
    func reloadService() {
        // Recreate service with updated token
    }
    
    func loadContents(path: String = "") async {
        guard !settings.owner.isEmpty && !settings.repo.isEmpty else {
            errorMessage = "No repository configured. Open Settings."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await service.fetchRepositoryContents(owner: settings.owner, repo: settings.repo, path: path)
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
            markdownContent = try await service.fetchFileContent(owner: settings.owner, repo: settings.repo, path: item.path)
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
