import SwiftUI

struct FullScreenNotificationView: View {
    let duration: Int
    let onClose: () -> Void
    
    @State private var randomMessage: String = ""
    
    private let encouragingMessages = [
        "休息是为了走更长远的路。",
        "喝口水，眺望一下远方吧。",
        "保持专注很棒，但也要注意休息哦。",
        "活动一下筋骨，让身体苏醒过来。",
        "短暂的抽离，是为了更好的回归。",
        "给大脑放个假，它会感谢你的。",
        "深呼吸，感受当下的宁静。",
        "站起来走走，让灵感重新流动。"
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Optional: Tap background to close? Maybe better to force button click.
                }
            
            // Notification Content
            VStack(spacing: 25) {
                // Icon
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // Main Title
                Text("已连续专注 \(duration) 分钟")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Encouraging Message
                Text(randomMessage)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Action Button
                Button(action: onClose) {
                    Text("我知道了，去休息一下")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(hex: "#1a1a1a").opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(20)
        }
        .onAppear {
            randomMessage = encouragingMessages.randomElement() ?? "休息一下吧"
        }
    }
}
