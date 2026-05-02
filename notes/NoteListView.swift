import SwiftUI

struct JDBreadcrumbView: View {
    let path: String
    
    private var segments: [String] {
        path.split(separator: "/").map(String.init)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Text("Root")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(segments, id: \.self) { segment in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(segment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct JDListRow: View {
    let item: GitHubItem
    let info: JDInfo
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: info.level.icon)
                .foregroundColor(info.level.color)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background(info.level.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if !info.displayNumber.isEmpty {
                        Text(info.displayNumber)
                            .font(.system(.caption, design: .rounded).bold().monospaced())
                            .foregroundColor(info.level.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
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
            
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.teal)
            }
        }
        .padding(.vertical, 4)
    }
}

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
            $0.jdInfo.displayNumber.localizedStandardCompare($1.jdInfo.displayNumber) == .orderedAscending
        }
        let files = viewModel.items.filter { !$0.isDirectory && $0.isMarkdown }.sorted {
            $0.jdInfo.displayNumber.localizedStandardCompare($1.jdInfo.displayNumber) == .orderedAscending
        }
        
        var groups: [(String, [GitHubItem])] = []
        if !dirs.isEmpty { groups.append(("Categories", dirs)) }
        if !files.isEmpty { groups.append(("Notes", files)) }
        return groups
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                    }
                }
                
                if !settings.isConfigured {
                    Section {
                        Text("No repository configured")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Button("Configure Repository") {
                            showSettings = true
                        }
                    }
                }
                
                if viewModel.isLoading {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                
                ForEach(groupedItems, id: \.0) { title, items in
                    Section(title) {
                        ForEach(items) { item in
                            if item.isDirectory {
                                Button {
                                    viewModel.navigateToDirectory(item)
                                } label: {
                                    JDListRow(item: item, info: item.jdInfo)
                                }
                            } else if item.isMarkdown {
                                NavigationLink {
                                    NoteDetailView(viewModel: viewModel, item: item)
                                } label: {
                                    JDListRow(item: item, info: item.jdInfo)
                                }
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
        }
    }
    
    private var titleForCurrentLevel: String {
        if viewModel.currentPath.isEmpty { return "Areas" }
        let components = viewModel.currentPath.split(separator: "/")
        guard let last = components.last.map(String.init) else { return "Browse" }
        return last
    }
}

#Preview {
    NoteListView()
}
