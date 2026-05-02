import Foundation
import SwiftUI

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
