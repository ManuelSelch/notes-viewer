import SwiftUI
import Textual

struct NoteDetailView: View {
    @ObservedObject var viewModel: NotesViewModel
    let item: GitHubItem
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                StructuredText(
                    markdown: viewModel.markdownContent,
                    syntaxExtensions: [.math]
                )
                .padding()
            }
        }
        .navigationTitle(item.name)
        .task {
            await viewModel.loadFile(item)
        }
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(
            viewModel: NotesViewModel(owner: "ManuelSelch", repo: "pi-memory-md"),
            item: GitHubItem(
                name: "README.md",
                path: "README.md",
                sha: "abc",
                size: 100,
                url: "",
                htmlUrl: "",
                gitUrl: "",
                downloadUrl: nil,
                type: "file"
            )
        )
    }
}
