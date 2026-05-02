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
                    Text(info.level.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(info.title)
                    .font(.body)
                    .lineLimit(1)
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
    
    private var results: [GitHubItem] {
        guard query.count >= 1 else { return [] }
        return viewModel.items.filter { item in
            let info = item.jdInfo
            let searchText = "\(info.displayNumber)\(info.title)".lowercased()
            return searchText.contains(query.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty && !query.isEmpty {
                    ContentUnavailableView("No results", systemImage: "magnifyingglass")
                }
                
                ForEach(results) { item in
                    if item.isDirectory {
                        Button {
                            viewModel.navigateToDirectory(item)
                            dismiss()
                        } label: {
                            SearchResultRow(item: item, info: item.jdInfo)
                        }
                    } else if item.isMarkdown {
                        NavigationLink {
                            NoteDetailView(viewModel: viewModel, item: item)
                        } label: {
                            SearchResultRow(item: item, info: item.jdInfo)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if viewModel.items.isEmpty && viewModel.settings.isConfigured {
                    await viewModel.loadContents()
                }
            }
        }
    }
}
