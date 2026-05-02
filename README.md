# Notes

A SwiftUI iOS app for browsing and rendering markdown notes stored in a GitHub repository. Built around the [Johnny Decimal](https://johnnydecimal.com/) organization system with support for custom prefixed indices.

## Features

- **GitHub Integration** — Fetch markdown content from any public or private GitHub repository
- **Johnny Decimal Navigation** — Browse notes using JD numbering with automatic level detection (areas, categories, items)
- **Custom System Prefixes** — Support for prefixed indices like `ITSec.S02.01` or `U03 S02.01`
- **Offline Cache** — Notes and directory listings cached locally for offline reading
- **Favorites** — Save frequently accessed folders for quick access from the root view
- **Recursive Search** — Search across all files in the repository
- **Recursive Download** — Swipe to download an entire folder tree for offline use
- **Folder Notes** — Special "readme" files matching parent folder names shown at the top
- **Secure Token Storage** — GitHub API tokens stored in iOS Keychain

## Architecture

| File | Purpose |
|---|---|
| `notesApp.swift` | App entry point |
| `ContentView.swift` | Main content container |
| `GitHubService.swift` | GitHub API client with async/await |
| `NotesViewModel.swift` | Main view model for list browsing |
| `NoteListView.swift` | Folder/file list with JD grouping |
| `NoteDetailView.swift` | Markdown rendering view |
| `SearchView.swift` | Recursive file search |
| `SettingsView.swift` | Repository and token configuration |
| `SettingsStore.swift` | Persistent settings (UserDefaults + Keychain) |
| `OfflineCache.swift` | Actor-based disk cache for offline support |
| `JDParser.swift` | Johnny Decimal pattern detection |
| `KeychainHelper.swift` | Secure token storage wrapper |

## Johnny Decimal Patterns Supported

### Standard JD
- `10-19 Finance` — Area
- `11 Accounts` — Category
- `11.01 Bank statements.md` — Item

### Prefixed (dot separator)
- `ITSec.S` — Area
- `ITSec.S02` — Category
- `ITSec.S02.01.md` — Item
- `GBS.10` — Category (numeric, no letter)
- `GBS.10.01.md` — Item (numeric, no letter)

### Prefixed (space separator)
- `U03 S` — Area
- `U03 S02` — Category
- `U03 S02.01.md` — Item
- `GBS 10` — Category (numeric, no letter)
- `GBS 10.01.md` — Item (numeric, no letter)

## Offline Behavior

| Scenario | Behavior |
|---|---|
| First launch online | Fetch from GitHub API, cache everything |
| Subsequent launch online | Show cache instantly, refresh in background |
| Offline with cache | Show cached data with "Offline" indicator |
| Offline no cache | Error message |

## Requirements

- iOS 17+
- Swift 6
- Xcode 15+

## Setup

1. Open `notes.xcodeproj` in Xcode
2. Build and run on device or simulator
3. Tap the gear icon to configure:
   - Repository owner (e.g., `ManuelSelch`)
   - Repository name (e.g., `pi-memory-md`)
   - GitHub token (optional, for private repos)

## License

MIT
