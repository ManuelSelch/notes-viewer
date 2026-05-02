import Foundation

enum GitHubError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case httpError(statusCode: Int)
}

nonisolated struct GitHubContent: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let url: String
    let htmlUrl: String
    let gitUrl: String
    let downloadUrl: String?
    let type: String
    let content: String?
    let encoding: String?
}

nonisolated struct GitHubItem: Codable, Identifiable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let url: String
    let htmlUrl: String
    let gitUrl: String
    let downloadUrl: String?
    let type: String
    
    var id: String { sha }
    var isDirectory: Bool { type == "dir" }
    var isMarkdown: Bool { name.hasSuffix(".md") }
}

actor GitHubService {
    private let session: URLSession
    private let baseURL = "https://api.github.com"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchRepositoryContents(owner: String, repo: String, path: String = "") async throws -> [GitHubItem] {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let endpoint = "\(baseURL)/repos/\(owner)/\(repo)/contents/\(encodedPath)"
        print("fetch repo \(endpoint)")
        
        guard let url = URL(string: endpoint) else { throw GitHubError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw GitHubError.invalidResponse }
        
        guard httpResponse.statusCode == 200 else { throw GitHubError.httpError(statusCode: httpResponse.statusCode) }
        
        return try decoder.decode([GitHubItem].self, from: data)
    }
    
    func fetchFileContent(owner: String, repo: String, path: String) async throws -> String {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let endpoint = "\(baseURL)/repos/\(owner)/\(repo)/contents/\(encodedPath)"
        
        guard let url = URL(string: endpoint) else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GitHubError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let content = try decoder.decode(GitHubContent.self, from: data)
        
        guard let encodedContent = content.content?.replacingOccurrences(of: "\n", with: ""),
              let data = Data(base64Encoded: encodedContent),
              let decodedString = String(data: data, encoding: .utf8) else {
            throw GitHubError.decodingFailed
        }
        
        return decodedString
    }
}
