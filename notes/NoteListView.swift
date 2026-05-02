import SwiftUI

struct NoteListView: View {
    @StateObject private var viewModel: NotesViewModel
    @StateObject private var settings = SettingsStore()
    @State private var showSettings = false
    @State private var showSearch = false
    @State private var showJDSearch = false
    
    init() {
        let settings = SettingsStore()
        _viewModel = StateObject(wrappedValue: NotesViewModel(settings: settings))
        _settings = StateObject(wrappedValue: settings)
    }
    
    private var itemsWithReadme: (readme: GitHubItem?, remaining: [GitHubItem]) {
        let parentName = viewModel.currentPath.split(separator: "/").last.map(String.init) ?? ""
        guard !parentName.isEmpty else {
            return (nil, viewModel.items)
        }
        let readmeName = "\(parentName).md"
        var readme: GitHubItem?
        let remaining = viewModel.items.filter { item in
            if item.name == readmeName {
                readme = item
                return false
            }
            return true
        }
        return (readme, remaining)
    }
    
    private var favoriteItems: [GitHubItem] {
        guard viewModel.currentPath.isEmpty else { return [] }
        return settings.favorites.compactMap { path in
            let components = path.split(separator: "/").map(String.init)
            guard let name = components.last else { return nil }
            return GitHubItem(
                name: name,
                path: path,
                sha: path,
                size: 0,
                url: "",
                htmlUrl: "",
                gitUrl: "",
                downloadUrl: nil,
                type: "dir"
            )
        }
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
                    
                    // Favorites section (root only)
                    if !favoriteItems.isEmpty {
                        Section {
                            ForEach(favoriteItems) { item in
                                Button {
                                    viewModel.navigateToDirectory(item)
                                } label: {
                                    JDListRow(item: item, info: item.jdInfo, isCached: viewModel.isCached(item))
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        settings.toggleFavorite(path: item.path)
                                    } label: {
                                        Label("Unfavorite", systemImage: "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Favorites")
                                    .font(.footnote.bold())
                                    .textCase(nil)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    // Readme section (single folder note)
                    if let readme = itemsWithReadme.readme {
                        Section {
                            NavigationLink {
                                NoteDetailView(
                                    owner: viewModel.settings.owner,
                                    repo: viewModel.settings.repo,
                                    token: viewModel.settings.token,
                                    item: readme
                                )
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                        .frame(width: 38, height: 38)
                                        .background(Color.gray.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(readme.jdInfo.title)
                                            .font(.body)
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.isCached(readme) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Readme")
                                .font(.footnote.bold())
                                .textCase(nil)
                        }
                    }
                    
                    // All items in order
                    if !itemsWithReadme.remaining.isEmpty {
                        Section {
                            ForEach(itemsWithReadme.remaining) { item in
                                if item.isDirectory {
                                    Button {
                                        viewModel.navigateToDirectory(item)
                                    } label: {
                                        JDListRow(item: item, info: item.jdInfo, isCached: viewModel.isCached(item))
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            Task { await viewModel.downloadFolderRecursively(item) }
                                        } label: {
                                            Label("Download", systemImage: "arrow.down.circle")
                                        }
                                        .tint(.blue)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            settings.toggleFavorite(path: item.path)
                                        } label: {
                                            Label("Favorite", systemImage: settings.isFavorite(path: item.path) ? "star.fill" : "star")
                                        }
                                        .tint(.yellow)
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
                                Text("Index")
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
                .navigationBarTitleDisplayMode(.inline)
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
                                showJDSearch = true
                            } label: {
                                Label("JD Search", systemImage: "number")
                                    .labelStyle(.iconOnly)
                            }
                            
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
                .sheet(isPresented: $showJDSearch) {
                    JDSearchView(viewModel: viewModel)
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
            }
        }
    }
    
    private var titleForCurrentLevel: String {
        if viewModel.currentPath.isEmpty { return "Root" }
        let components = viewModel.currentPath.split(separator: "/")
        return components.last.map(String.init) ?? "Browse"
    }
}

#Preview {
    NoteListView()
}
