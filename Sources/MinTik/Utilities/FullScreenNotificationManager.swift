import AppKit
import SwiftUI

class FullScreenNotificationManager {
    static let shared = FullScreenNotificationManager()
    
    private var window: NSWindow?
    
    private init() {}
    
    func show(duration: Int) {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            self?.presentWindow(duration: duration)
        }
    }
    
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.close()
            self?.window = nil
        }
    }
    
    func showTest() {
        show(duration: 45) // Example duration for test
    }
    
    private func presentWindow(duration: Int) {
        // Close existing window if any
        window?.close()
        
        // Create a borderless panel that covers the screen
        let newWindow = NSPanel(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        newWindow.level = .statusBar // High level to float above other windows
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.hasShadow = false
        newWindow.ignoresMouseEvents = false // Needs to receive clicks for the button
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Critical: Don't include this panel in the window list
        // This prevents the app from terminating when the panel closes
        newWindow.hidesOnDeactivate = false
        newWindow.isFloatingPanel = true
        newWindow.becomesKeyOnlyIfNeeded = true
        
        // Create the SwiftUI view
        let contentView = FullScreenNotificationView(duration: duration) { [weak self] in
            self?.hide()
        }
        
        // Set the content view
        newWindow.contentView = NSHostingView(rootView: contentView)
        
        // Center and show
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        
        // Ensure it covers the whole screen properly
        if let screen = NSScreen.main {
            newWindow.setFrame(screen.frame, display: true)
        }
        
        self.window = newWindow
    }
}
