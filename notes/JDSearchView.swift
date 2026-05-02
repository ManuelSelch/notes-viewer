import SwiftUI

struct JDSearchView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var query: String = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredResults: [GitHubItem] {
        guard query.count >= 1 else { return [] }
        let lowerQuery = query.lowercased()
        return viewModel.searchResults.filter { item in
            let number = item.jdInfo.displayNumber.lowercased()
            return number.contains(lowerQuery)
        }
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
            .navigationTitle("Search JD Index")
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "e.g. 21.33, ITSec.S01"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if viewModel.settings.isConfigured && viewModel.searchResults.isEmpty {
                    await viewModel.buildSearchIndex()
                }
            }
        }
    }
}
