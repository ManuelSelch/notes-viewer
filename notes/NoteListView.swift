import SwiftUI

struct NoteListView: View {
    @StateObject private var viewModel: NotesViewModel
    
    init(owner: String, repo: String) {
        _viewModel = StateObject(wrappedValue: NotesViewModel(owner: owner, repo: repo))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
                
                ForEach(viewModel.items) { item in
                    if item.isDirectory {
                        Button {
                            viewModel.navigateToDirectory(item)
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.yellow)
                                Text(item.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    } else if item.isMarkdown {
                        NavigationLink {
                            NoteDetailView(viewModel: viewModel, item: item)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                Text(item.name)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle(viewModel.currentPath.isEmpty ? "Notes" : viewModel.currentPath)
            .toolbar {
                if viewModel.canGoBack {
                    ToolbarItem(placement: .navigation) { // navigationBarLeading
                        Button("Back") {
                            viewModel.navigateBack()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadContents()
        }
    }
}

#Preview {
    NoteListView(owner: "ManuelSelch", repo: "pi-memory-md")
}
