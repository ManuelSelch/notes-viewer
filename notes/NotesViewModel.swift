import Foundation
import SwiftUI
import Combine

@MainActor
class NotesViewModel: ObservableObject {
    @Published var items: [GitHubItem] = []
    @Published var markdownContent: String = ""
    @Published var isLoadingList = false
    @Published var isLoadingFile = false
    @Published var listError: String?
    @Published var fileError: String?
    @Published var currentPath: String = ""
    @Published var navigationStack: [String] = []
    
    let settings: SettingsStore
    private var service: GitHubService
    private let cache = DirectoryCache.shared
    
    init(settings: SettingsStore) {
        self.settings = settings
        self.service = GitHubService(token: settings.token)
    }
    
    func reloadService(token: String) {
        service = GitHubService(token: token)
    }
    
    func loadContents(path: String = "") async {
        guard !settings.owner.isEmpty && !settings.repo.isEmpty else {
            listError = "No repository configured. Open Settings."
            return
        }
        
        isLoadingList = true
        listError = nil
        
        // Clear stale items while loading so user doesn't see wrong data
        if path != currentPath {
            items = []
        }
        
        // Try cache first for instant display
        if let cached = await cache.get(for: path) {
            items = cached
        }
        
        do {
            let freshItems = try await service.fetchRepositoryContents(owner: settings.owner, repo: settings.repo, path: path)
            items = freshItems
            currentPath = path
            await cache.set(items: freshItems, for: path)
        } catch {
            // If we have cached items, keep them and show a subtle error
            if items.isEmpty {
                listError = error.localizedDescription
            } else {
                listError = "\(error.localizedDescription) — showing cached data"
            }
        }
        
        isLoadingList = false
    }
    
    func loadFile(_ item: GitHubItem) async {
        guard item.isMarkdown else { return }
        
        isLoadingFile = true
        fileError = nil
        markdownContent = ""
        
        do {
            markdownContent = try await service.fetchFileContent(owner: settings.owner, repo: settings.repo, path: item.path)
        } catch {
            fileError = error.localizedDescription
        }
        
        isLoadingFile = false
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
    
    func clearCache() {
        Task {
            await cache.clear()
        }
    }
}
