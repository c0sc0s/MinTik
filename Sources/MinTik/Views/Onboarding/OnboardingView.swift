import SwiftUI

struct OnboardingView: View {
    @ObservedObject var vm: FocusViewModel
    @State private var currentPage = 0
    
    // Page 1 State
    @State private var opacityPage1 = 0.0
    @State private var blurPage1: CGFloat = 10.0
    @State private var textOffsetPage1: CGFloat = 20.0
    
    // Page 3 State
    @State private var inputName: String = ""
    @FocusState private var isNameFocused: Bool
    
    // Global Animation State
    @State private var breathingPhase = 0.0
    @State private var floatingOffset: CGFloat = 0.0
    @State private var buttonHovered = false
    @State private var pageScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 1. Window Shape & Background
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "1a1a1a"),
                            Color(hex: "0a0a0a"),
                            Color.black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.35)
                .background(
                    VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
            
            // 2. Dynamic Lighting (Breathing Gradient)
            GeometryReader { proxy in
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.04),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.3 + 0.1 * cos(breathingPhase), y: 0.3 + 0.1 * sin(breathingPhase)),
                    startRadius: 0,
                    endRadius: proxy.size.width * 1.2
                )
                .opacity(0.7 + 0.3 * sin(breathingPhase))
                .blendMode(.overlay)
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        breathingPhase = .pi * 2
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
            
            // 3. Content
            ZStack {
                if currentPage == 0 {
                    page1
                        .scaleEffect(pageScale)
                } else if currentPage == 1 {
                    page2
                        .scaleEffect(pageScale)
                } else if currentPage == 2 {
                    page3
                        .scaleEffect(pageScale)
                } else if currentPage == 3 {
                    page4
                        .scaleEffect(pageScale)
                }
            }
            .padding(40)
        }
        .frame(width: 550, height: 380)
        .background(Color.clear)
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Page 1: Intro
    var page1: some View {
        VStack(spacing: 8) {
            Text("你的每一刻")
                .font(.system(size: 28, weight: .thin, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0)
                .offset(y: textOffsetPage1)
            
            Text("都值得关心")
                .font(.system(size: 36, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.7), radius: 15, x: 0, y: 0)
                .offset(y: textOffsetPage1)
        }
        .opacity(opacityPage1)
        .blur(radius: blurPage1)
        .onAppear {
            pageScale = 0.9
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                pageScale = 1.0
            }
            
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                opacityPage1 = 1.0
                blurPage1 = 0
                textOffsetPage1 = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.6)) {
                    opacityPage1 = 0.0
                    blurPage1 = 10
                    textOffsetPage1 = -10
                    pageScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    currentPage = 1
                }
            }
        }
    }
    
    // MARK: - Page 2: Focus Duration
    var page2: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("专注")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Text("你习惯连续工作多久?")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(spacing: -5) {
                Text("\(Int(vm.config.duration))")
                    .font(.system(size: 110, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .shadow(color: .white.opacity(0.25), radius: 20, x: 0, y: 0)
                    .offset(y: floatingOffset)
                Text("MINUTES")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .tracking(6)
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    floatingOffset = -5
                }
            }
            
            Spacer()
            
            VStack(spacing: 30) {
                Slider(value: $vm.config.duration, in: 10...90, step: 5)
                    .accentColor(.white)
                    .padding(.horizontal, 40)
                
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPage = 2
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("NEXT")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .tracking(2)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                                .rotationEffect(.degrees(buttonHovered ? 0 : -45))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(buttonHovered ? 0.15 : 0.08))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(buttonHovered ? 0.2 : 0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .scaleEffect(buttonHovered ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonHovered = hovering
                        }
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity.combined(with: .scale(scale: 1.05))))
    }
    
    // MARK: - Page 3: Notifications
    var page3: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("通知")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Text("不错过休息提醒")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                    .offset(y: floatingOffset)
                
                Text("MinTik 需要通知权限来提醒你休息。\n我们保证只在必要时打扰。")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    floatingOffset = -5
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    if vm.notificationState == .authorized || vm.notificationState == .provisional {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentPage = 3
                        }
                    } else if vm.notificationState == .denied {
                        vm.openNotificationPreferences()
                    } else {
                        vm.requestNotificationPermission()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(vm.notificationState == .denied ? "OPEN SETTINGS" : (vm.notificationState == .authorized ? "NEXT" : "ENABLE & NEXT"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(buttonHovered ? 0 : -45))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(buttonHovered ? 0.15 : 0.08))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(buttonHovered ? 0.2 : 0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .scaleEffect(buttonHovered ? 1.05 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        buttonHovered = hovering
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity.combined(with: .scale(scale: 1.05))))
        .onChange(of: vm.notificationState) { newState in
            if currentPage == 2 && (newState == .authorized || newState == .provisional) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentPage = 3
                    }
                }
            }
        }
    }
    
    // MARK: - Page 4: Name
    var page4: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("称呼")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Text("最后一个问题")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    if inputName.isEmpty {
                        Text("我")
                            .font(.system(size: 56, weight: .light, design: .rounded))
                            .foregroundColor(.white.opacity(0.15))
                    }
                    TextField("", text: $inputName, onCommit: completeOnboarding)
                        .focused($isNameFocused)
                        .textFieldStyle(.plain)
                        .font(.system(size: 56, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .frame(width: 250)
                        .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 0)
                }
                
                Rectangle()
                    .frame(width: 50, height: 2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            VStack {
                Text("PRESS ENTER TO CONFIRM")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 20)
                    .opacity(inputName.isEmpty ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: inputName.isEmpty)
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
    
    private func completeOnboarding() {
        guard !inputName.isEmpty else { return }
        vm.config.userName = inputName
        // Enable launch at login silently
        vm.config.launchAtLogin = true
        vm.completeOnboarding()
    }
}
