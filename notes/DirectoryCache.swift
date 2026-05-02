import Foundation

actor DirectoryCache {
    static let shared = DirectoryCache()
    
    private var cache: [String: CachedEntry] = [:]
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    struct CachedEntry: Codable {
        let items: [GitHubItem]
        let timestamp: Date
    }
    
    private init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("notes_cache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        loadFromDisk()
    }
    
    func get(for path: String) -> [GitHubItem]? {
        guard let entry = cache[path], entry.timestamp.timeIntervalSinceNow > -300 else { return nil }
        return entry.items
    }
    
    func set(items: [GitHubItem], for path: String) {
        cache[path] = CachedEntry(items: items, timestamp: Date())
        saveToDisk()
    }
    
    func clear() {
        cache.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func diskURL(for path: String) -> URL {
        let key = path.data(using: .utf8)?.base64EncodedString() ?? path
        return cacheDirectory.appendingPathComponent("\(key).json")
    }
    
    private func loadFromDisk() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        for url in files where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let entry = try? JSONDecoder().decode(CachedEntry.self, from: data) else { continue }
            if entry.timestamp.timeIntervalSinceNow > -86400 {
                // Only load if < 24h old
                let path = url.deletingPathExtension().lastPathComponent
                if let decodedPath = Data(base64Encoded: path),
                   let key = String(data: decodedPath, encoding: .utf8) {
                    cache[key] = entry
                }
            }
        }
    }
    
    private func saveToDisk() {
        for (path, entry) in cache {
            let url = diskURL(for: path)
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: url)
            }
        }
    }
}
