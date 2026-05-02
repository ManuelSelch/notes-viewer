import SwiftUI

struct NoteListView: View {
    @StateObject private var viewModel: NotesViewModel
    @StateObject private var settings = SettingsStore()
    @State private var showSettings = false
    @State private var showSearch = false
    
    init() {
        let settings = SettingsStore()
        _viewModel = StateObject(wrappedValue: NotesViewModel(settings: settings))
        _settings = StateObject(wrappedValue: settings)
    }
    
    private var groupedItems: [(String, [GitHubItem])] {
        let dirs = viewModel.items.filter { $0.isDirectory }.sorted {
            let num0 = $0.jdInfo.displayNumber
            let num1 = $1.jdInfo.displayNumber
            return num0.localizedStandardCompare(num1) == .orderedAscending
        }
        let files = viewModel.items.filter { $0.isMarkdown && !$0.isDirectory }.sorted {
            let num0 = $0.jdInfo.displayNumber
            let num1 = $1.jdInfo.displayNumber
            return num0.localizedStandardCompare(num1) == .orderedAscending
        }
        
        var groups: [(String, [GitHubItem])] = []
        if !dirs.isEmpty { groups.append(("Categories", dirs)) }
        if !files.isEmpty { groups.append(("Notes", files)) }
        return groups
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    if let error = viewModel.listError {
                        Section {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.callout)
                                .foregroundColor(.orange)
                        }
                        .listRowBackground(Color.orange.opacity(0.08))
                    }
                    
                    if !settings.isConfigured {
                        Section {
                            Text("No repository configured")
                                .foregroundColor(.secondary)
                            Button("Configure Repository") {
                                showSettings = true
                            }
                        }
                    }
                    
                    if viewModel.isLoadingList && viewModel.items.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                ProgressView().scaleEffect(1.2)
                                Text("Loading…")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    ForEach(groupedItems, id: \.0) { title, items in
                        Section {
                            ForEach(items) { item in
                                if item.isDirectory {
                                    Button {
                                        viewModel.navigateToDirectory(item)
                                    } label: {
                                        JDListRow(item: item, info: item.jdInfo, isCached: viewModel.isCached(item))
                                    }
                                } else if item.isMarkdown {
                                    NavigationLink {
                                        NoteDetailView(
                                            owner: viewModel.settings.owner,
                                            repo: viewModel.settings.repo,
                                            token: viewModel.settings.token,
                                            item: item
                                        )
                                    } label: {
                                        JDListRow(item: item, info: item.jdInfo, isCached: viewModel.isCached(item))
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text(title)
                                    .font(.footnote.bold())
                                    .textCase(nil)
                                
                                if viewModel.isOffline {
                                    Spacer()
                                    Label("Offline", systemImage: "wifi.slash")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(titleForCurrentLevel)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if viewModel.canGoBack {
                            Button {
                                viewModel.navigateBack()
                            } label: {
                                Label("Back", systemImage: "arrow.left")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                showSearch = true
                            } label: {
                                Label("Search", systemImage: "magnifyingglass")
                                    .labelStyle(.iconOnly)
                            }
                            
                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gear")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(settings: settings)
                }
                .sheet(isPresented: $showSearch) {
                    SearchView(viewModel: viewModel)
                }
                .onChange(of: settings.owner) { _, _ in
                    viewModel.reloadService(token: settings.token)
                    Task { await viewModel.loadContents() }
                }
                .onChange(of: settings.repo) { _, _ in
                    viewModel.reloadService(token: settings.token)
                    Task { await viewModel.loadContents() }
                }
                .task {
                    if settings.isConfigured && viewModel.items.isEmpty {
                        await viewModel.loadContents()
                    }
                }
                .refreshable {
                    if settings.isConfigured {
                        await viewModel.loadContents(path: viewModel.currentPath)
                    }
                }
                
                // Updating overlay when we have cached data
                if viewModel.isLoadingList && !viewModel.items.isEmpty {
                    VStack {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text("Updating…")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private var titleForCurrentLevel: String {
        if viewModel.currentPath.isEmpty { return "Areas" }
        let components = viewModel.currentPath.split(separator: "/")
        return components.last.map(String.init) ?? "Browse"
    }
}

#Preview {
    NoteListView()
}
