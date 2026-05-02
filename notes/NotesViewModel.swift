import Foundation
import SwiftUI
import Combine

@MainActor
class NotesViewModel: ObservableObject {
    @Published var items: [GitHubItem] = []
    @Published var markdownContent: String = ""
    @Published var isLoadingList = false
    @Published var isLoadingFile = false
    @Published var isOffline = false
    @Published var listError: String?
    @Published var fileError: String?
    @Published var currentPath: String = ""
    @Published var navigationStack: [String] = []
    
    let settings: SettingsStore
    private var service: GitHubService
    private let cache = OfflineCache.shared
    
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
        
        listError = nil
        
        // Check cache first — show instantly if available
        if let cached = await cache.directory(for: path) {
            items = cached
            currentPath = path
            isOffline = true
            
            // If we have no network, don't bother trying to refresh
            guard await hasNetwork() else { return }
        }
        
        isLoadingList = true
        
        // Clear before fetching to avoid stale data mismatch
        if !items.isEmpty {
            items = []
        }
        
        do {
            let freshItems = try await service.fetchRepositoryContents(owner: settings.owner, repo: settings.repo, path: path)
            items = freshItems
            currentPath = path
            isOffline = false
            await cache.setDirectory(items: freshItems, for: path)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            // Network offline — cache already shown above
            items = await cache.directory(for: path) ?? []
            isOffline = true
        } catch {
            let cached = await cache.directory(for: path)
            if cached != nil {
                items = cached!
                isOffline = true
                listError = "Offline — showing cached data"
            } else {
                listError = error.localizedDescription
                items = []
            }
        }
        
        isLoadingList = false
    }
    
    func loadFile(_ item: GitHubItem) async {
        guard item.isMarkdown else { return }
        
        isLoadingFile = true
        fileError = nil
        markdownContent = ""
        
        if let cached = await cache.file(for: item.path) {
            markdownContent = cached
            isOffline = true
            
            guard await hasNetwork() else {
                isLoadingFile = false
                return
            }
        }
        
        do {
            let content = try await service.fetchFileContent(owner: settings.owner, repo: settings.repo, path: item.path)
            markdownContent = content
            isOffline = false
            await cache.setFile(content: content, for: item.path)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            if let cached = await cache.file(for: item.path) {
                markdownContent = cached
                isOffline = true
            } else {
                fileError = "No network — file not cached"
            }
        } catch {
            if let cached = await cache.file(for: item.path) {
                markdownContent = cached
                isOffline = true
                fileError = "Offline — showing cached content"
            } else {
                fileError = error.localizedDescription
            }
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
    
    private func hasNetwork() async -> Bool {
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
