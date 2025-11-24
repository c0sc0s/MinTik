import SwiftUI

@main
struct MinTik: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            if FocusViewModel.shared.config.isFirstLaunch {
                OnboardingView(vm: FocusViewModel.shared)
                    .background(Color(hex: "121212"))
            } else {
                ModernFocusUI(vm: FocusViewModel.shared)
                    .background(Color.clear)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
    }
}
