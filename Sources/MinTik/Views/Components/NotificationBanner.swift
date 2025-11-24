import SwiftUI

struct NotificationPermissionBanner: View {
    var title: String
    var detail: String
    var actionTitle: String?
    var backgroundColor: Color
    var accent: Color
    var textPrimary: Color
    var textSecondary: Color
    var action: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundColor(accent)
                .font(.system(size: 16, weight: .bold))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.15))
                        .foregroundColor(accent)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(14)
    }
}
