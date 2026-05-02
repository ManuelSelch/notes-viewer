import Foundation

actor OfflineCache {
    static let shared = OfflineCache()
    
    private var directories: [String: DirectoryEntry] = [:]
    private var files: [String: FileEntry] = [:]
    private var hasLoaded = false
    
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let dirsURL: URL
    private let filesURL: URL
    
    struct DirectoryEntry: Codable {
        let items: [GitHubItem]
        let cachedAt: Date
    }
    
    struct FileEntry: Codable {
        let content: String
        let cachedAt: Date
    }
    
    private init() {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseURL = support.appendingPathComponent("NotesOfflineCache")
        dirsURL = baseURL.appendingPathComponent("dirs")
        filesURL = baseURL.appendingPathComponent("files")
        try? fileManager.createDirectory(at: dirsURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: filesURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Directories
    
    func directory(for path: String) -> [GitHubItem]? {
        ensureLoaded()
        return directories[path]?.items
    }
    
    func setDirectory(items: [GitHubItem], for path: String) {
        ensureLoaded()
        directories[path] = DirectoryEntry(items: items, cachedAt: Date())
        persistDirectory(path: path)
    }
    
    func hasDirectory(for path: String) -> Bool {
        ensureLoaded()
        return directories[path] != nil
    }
    
    // MARK: - Files
    
    func file(for path: String) -> String? {
        ensureLoaded()
        return files[path]?.content
    }
    
    func setFile(content: String, for path: String) {
        ensureLoaded()
        files[path] = FileEntry(content: content, cachedAt: Date())
        persistFile(path: path)
    }
    
    func hasFile(for path: String) -> Bool {
        ensureLoaded()
        return files[path] != nil
    }
    
    func fileCachedAt(for path: String) -> Date? {
        ensureLoaded()
        return files[path]?.cachedAt
    }
    
    func cacheStatus(for item: GitHubItem) -> CacheStatus {
        ensureLoaded()
        if item.isMarkdown {
            return files[item.path] != nil ? .cached : .notCached
        }
        if item.isDirectory {
            return folderFullyCached(item.path) ? .cached : .notCached
        }
        return .notCached
    }
    
    func folderFullyCached(_ path: String) -> Bool {
        ensureLoaded()
        guard let items = directories[path]?.items else { return false }
        for item in items {
            if item.isMarkdown && files[item.path] == nil {
                return false
            }
            if item.isDirectory && !folderFullyCached(item.path) {
                return false
            }
        }
        return true
    }
    
    // MARK: - Clearing
    
    enum CacheStatus {
        case cached
        case notCached
    }
    
    func clear() {
        directories.removeAll()
        files.removeAll()
        try? fileManager.removeItem(at: baseURL)
        try? fileManager.createDirectory(at: dirsURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: filesURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Private
    
    private func ensureLoaded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadDirectories()
        loadFiles()
    }
    
    private func safeKey(_ path: String) -> String {
        path.data(using: .utf8)?.base64EncodedString() ?? path.replacingOccurrences(of: "/", with: "_")
    }
    
    private func directoryFileURL(for path: String) -> URL {
        dirsURL.appendingPathComponent(safeKey(path)).appendingPathExtension("json")
    }
    
    private func fileContentURL(for path: String) -> URL {
        filesURL.appendingPathComponent(safeKey(path)).appendingPathExtension("md")
    }
    
    private func loadDirectories() {
        guard let urls = try? fileManager.contentsOfDirectory(at: dirsURL, includingPropertiesForKeys: nil) else { return }
        for url in urls where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let entry = try? JSONDecoder().decode(DirectoryEntry.self, from: data) else { continue }
            let key = url.deletingPathExtension().lastPathComponent
            guard let decoded = Data(base64Encoded: key),
                  let path = String(data: decoded, encoding: .utf8), !path.isEmpty else { continue }
            directories[path] = entry
        }
    }
    
    private func loadFiles() {
        guard let urls = try? fileManager.contentsOfDirectory(at: filesURL, includingPropertiesForKeys: nil) else { return }
        for url in urls where url.pathExtension == "md" {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let key = url.deletingPathExtension().lastPathComponent
            guard let decoded = Data(base64Encoded: key),
                  let path = String(data: decoded, encoding: .utf8), !path.isEmpty else { continue }
            let attr = try? fileManager.attributesOfItem(atPath: url.path)
            let modDate = attr?[.modificationDate] as? Date ?? Date.distantPast
            files[path] = FileEntry(content: content, cachedAt: modDate)
        }
    }
    
    private func persistDirectory(path: String) {
        guard let entry = directories[path] else { return }
        let url = directoryFileURL(for: path)
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: url)
        }
    }
    
    private func persistFile(path: String) {
        guard let entry = files[path] else { return }
        let url = fileContentURL(for: path)
        try? entry.content.write(to: url, atomically: true, encoding: .utf8)
    }
}
