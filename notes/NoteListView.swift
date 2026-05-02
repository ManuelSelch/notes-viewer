import SwiftUI

struct NoteListView: View {
    @StateObject private var viewModel: NotesViewModel
    @StateObject private var settings = SettingsStore()
    @State private var showSettings = false
    
    init() {
        let settings = SettingsStore()
        _viewModel = StateObject(wrappedValue: NotesViewModel(settings: settings))
        _settings = StateObject(wrappedValue: settings)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
                
                if !settings.isConfigured {
                    Section {
                        Text("No repository configured")
                            .foregroundColor(.secondary)
                        Button("Open Settings") {
                            showSettings = true
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .onChange(of: settings.owner) { _, _ in
                Task { await viewModel.loadContents() }
            }
            .onChange(of: settings.repo) { _, _ in
                Task { await viewModel.loadContents() }
            }
            .task {
                if settings.isConfigured {
                    await viewModel.loadContents()
                }
            }
        }
    }
}

#Preview {
    NoteListView()
}
