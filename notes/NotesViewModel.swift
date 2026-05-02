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
    @Published var searchResults: [GitHubItem] = []
    @Published var isBuildingSearchIndex = false
    
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
        
        if let cached = await cache.directory(for: path) {
            items = cached
            currentPath = path
            isOffline = true
            guard await hasNetwork() else { return }
        }
        
        isLoadingList = true
        
        if path != currentPath {
            items = []
        }
        
        do {
            let freshItems = try await service.fetchRepositoryContents(owner: settings.owner, repo: settings.repo, path: path)
            items = freshItems
            currentPath = path
            isOffline = false
            await cache.setDirectory(items: freshItems, for: path)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            items = await cache.directory(for: path) ?? []
            isOffline = true
        } catch {
            if let cached = await cache.directory(for: path) {
                items = cached
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
            fileError = "No network — file not cached"
            isOffline = true
        } catch {
            if markdownContent.isEmpty {
                fileError = error.localizedDescription
            } else {
                isOffline = true
                fileError = "Offline — showing cached content"
            }
        }
        
        isLoadingFile = false
    }
    
    // MARK: - Recursive Search
    
    func buildSearchIndex(from rootPath: String = "") async {
        guard !settings.owner.isEmpty && !settings.repo.isEmpty else { return }
        isBuildingSearchIndex = true
        var allFiles: [GitHubItem] = []
        
        await crawl(rootPath, into: &allFiles)
        
        searchResults = allFiles.sorted {
            $0.jdInfo.displayNumber.localizedStandardCompare($1.jdInfo.displayNumber) == .orderedAscending
        }
        isBuildingSearchIndex = false
    }
    
    private func crawl(_ path: String, into results: inout [GitHubItem]) async {
        // Try cache first, then network
        var items: [GitHubItem] = []
        
        if let cached = await cache.directory(for: path) {
            items = cached
        }
        
        if items.isEmpty {
            do {
                items = try await service.fetchRepositoryContents(owner: settings.owner, repo: settings.repo, path: path)
                await cache.setDirectory(items: items, for: path)
            } catch {
                return // Skip this path if we can't fetch
            }
        }
        
        for item in items {
            if item.isMarkdown {
                results.append(item)
            } else if item.isDirectory {
                await crawl(item.path, into: &results)
            }
        }
    }
    
    func search(query: String) -> [GitHubItem] {
        guard query.count >= 1 else { return [] }
        let lowerQuery = query.lowercased()
        return searchResults.filter { item in
            let info = item.jdInfo
            let text = "\(info.displayNumber)\(info.title)".lowercased()
            return text.contains(lowerQuery)
        }
    }
    
    // MARK: - Navigation
    
    func navigateToDirectory(_ item: GitHubItem) {
        guard item.isDirectory else { return }
        navigationStack.append(currentPath)
        Task { await loadContents(path: item.path) }
    }
    
    func navigateBack() {
        guard let previousPath = navigationStack.popLast() else { return }
        Task { await loadContents(path: previousPath) }
    }
    
    var canGoBack: Bool { !navigationStack.isEmpty }
    
    func clearCache() {
        Task { await cache.clear() }
    }
    
    private func hasNetwork() async -> Bool {
        var request = URLRequest(url: URL(string: "https://api.github.com")!)
        request.timeoutInterval = 3
        do {
            _ = try await URLSession.shared.data(for: request)
            return true
        } catch { return false }
    }
}
