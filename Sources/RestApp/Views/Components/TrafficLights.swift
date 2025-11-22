import SwiftUI

struct TrafficLightsView: View {
    @State private var isHovering = false
    @Environment(\.controlActiveState) var controlActiveState
    var isActive: Bool { controlActiveState == .key || controlActiveState == .active }
    
    var body: some View {
        HStack(spacing: 7) {
            TrafficLightCircle(color: isActive ? Color(hex: "FF5F57") : Color(hex: "585858"), stroke: isActive ? Color(hex: "E0443E") : Color.clear, symbol: "xmark", isHovering: isHovering) {
                NotificationCenter.default.post(name: .restAppRequestHide, object: nil)
            }
            TrafficLightCircle(color: isActive ? Color(hex: "FEBC2E") : Color(hex: "585858"), stroke: isActive ? Color(hex: "D89E24") : Color.clear, symbol: "minus", isHovering: isHovering) { NSApp.keyWindow?.miniaturize(nil) }
            TrafficLightCircle(color: isActive ? Color(hex: "28C840") : Color(hex: "585858"), stroke: isActive ? Color(hex: "1AAB29") : Color.clear, symbol: "plus", isHovering: isHovering) { NSApp.keyWindow?.zoom(nil) }
        }
        .onHover { isHovering = $0 }
    }
}

struct TrafficLightCircle: View {
    var color, stroke: Color
    var symbol: String
    var isHovering: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(color).frame(width: 11, height: 11).overlay(Circle().stroke(stroke, lineWidth: 0.5))
                if isHovering {
                    Image(systemName: symbol)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 11, height: 11) // Ensure centered
                }
            }
            .frame(width: 11, height: 11) // Explicit frame
        }
        .buttonStyle(.plain)
    }
}
