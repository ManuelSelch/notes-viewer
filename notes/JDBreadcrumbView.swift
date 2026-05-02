import Foundation
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
