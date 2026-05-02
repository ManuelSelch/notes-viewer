import SwiftUI

struct SearchResultRow: View {
    let item: GitHubItem
    let info: JDInfo
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: info.level.icon)
                .foregroundColor(info.level.color)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(info.level.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if !info.displayNumber.isEmpty {
                        Text(info.displayNumber)
                            .font(.caption.bold())
                            .foregroundColor(info.level.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(info.level.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(info.title)
                    .font(.body)
                    .lineLimit(1)
                
                // Show parent path
                let parentPath = item.path.components(separatedBy: "/").dropLast().joined(separator: " / ")
                if !parentPath.isEmpty {
                    Text(parentPath)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SearchView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var query: String = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredResults: [GitHubItem] {
        viewModel.search(query: query)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.isBuildingSearchIndex {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Scanning repository…")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if !viewModel.isBuildingSearchIndex && filteredResults.isEmpty && !query.isEmpty {
                    ContentUnavailableView("No results", systemImage: "magnifyingglass")
                }
                
                ForEach(filteredResults) { item in
                    NavigationLink {
                        NoteDetailView(
                            owner: viewModel.settings.owner,
                            repo: viewModel.settings.repo,
                            token: viewModel.settings.token,
                            item: item
                        )
                    } label: {
                        SearchResultRow(item: item, info: item.jdInfo)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search Notes")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if viewModel.settings.isConfigured {
                    await viewModel.buildSearchIndex(from: viewModel.currentPath)
                }
            }
        }
    }
}
