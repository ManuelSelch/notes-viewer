import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var owner: String {
        didSet { UserDefaults.standard.set(owner, forKey: "github_owner") }
    }
    
    @Published var repo: String {
        didSet { UserDefaults.standard.set(repo, forKey: "github_repo") }
    }
    
    @Published var token: String {
        didSet {
            if token.isEmpty {
                try? KeychainHelper.shared.delete(for: "github_token")
            } else {
                try? KeychainHelper.shared.save(token, for: "github_token")
            }
        }
    }
    
    var isConfigured: Bool {
        !owner.isEmpty && !repo.isEmpty
    }
    
    init() {
        self.owner = UserDefaults.standard.string(forKey: "github_owner") ?? ""
        self.repo = UserDefaults.standard.string(forKey: "github_repo") ?? ""
        self.token = (try? KeychainHelper.shared.read(for: "github_token")) ?? ""
    }
}
