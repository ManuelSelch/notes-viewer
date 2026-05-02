import Foundation
import SwiftUI

struct JDListRow: View {
    let item: GitHubItem
    let info: JDInfo
    let isCached: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.text.fill")
                .foregroundColor(item.isDirectory ? .blue : info.level.color)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background((item.isDirectory ? Color.blue : info.level.color).opacity(0.12))
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
                    
                    Text(item.isDirectory ? "Folder" : "Note")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(info.title)
                    .font(.body)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCached {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.teal)
            }
        }
        .padding(.vertical, 4)
    }
}
