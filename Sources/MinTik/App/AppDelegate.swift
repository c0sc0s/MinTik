import SwiftUI
import AppKit
import UserNotifications
import os

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let statusFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    private lazy var statusMenu: NSMenu = {
        let menu = NSMenu()
        let quit = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }()
    private let popover = NSPopover()
    private let hostingController = NSHostingController(rootView: ModernFocusUI(vm: FocusViewModel.shared))
    private var popoverShowCount = 0  // Counter to trigger animation on each show
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.lifecycle.notice("Application did finish launching")
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize popover content
        popover.contentViewController = hostingController
        // Force dark mode appearance
        popover.appearance = NSAppearance(named: .darkAqua)
        
        // Ensure hosting controller view is transparent for window usage
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        setupStatusItem()
        setupAppIcon()
        
        if NotificationAvailability.isAvailable {
            broadcastNotificationSettings()
            requestNotificationPermission()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleStatusUpdate(_:)), name: .MinTikStatusUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleHideRequest), name: .MinTikRequestHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnboardingCompleted), name: Notification.Name("MinTikOnboardingCompleted"), object: nil)
        
        DispatchQueue.main.async {
            if !FocusViewModel.shared.config.isFirstLaunch {
                if let window = NSApplication.shared.windows.first {
                    window.orderOut(nil)
                }
            } else {
                if let window = NSApplication.shared.windows.first {
                    // Set fixed window size to match SwiftUI content
                    let windowSize = NSSize(width: 550, height: 380)
                    window.setContentSize(windowSize)
                    
                    // Advanced Window Styling
                    window.level = .floating
                    window.styleMask = [.borderless, .fullSizeContentView]
                    window.isOpaque = false
                    window.backgroundColor = .clear
                    window.hasShadow = false
                    window.isMovableByWindowBackground = true
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    
                    // Force dark mode appearance
                    window.appearance = NSAppearance(named: .darkAqua)
                    
                    window.invalidateShadow()
                    
                    // Ensure content view is transparent
                    window.contentView?.wantsLayer = true
                    window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
                    
                    // Recursively clear background of all subviews
                    func clearBackground(of view: NSView) {
                        view.wantsLayer = true
                        view.layer?.backgroundColor = NSColor.clear.cgColor
                        for subview in view.subviews {
                            clearBackground(of: subview)
                        }
                    }
                    if let contentView = window.contentView {
                        clearBackground(of: contentView)
                        
                        let maskLayer = CAShapeLayer()
                        let cornerRadius: CGFloat = 24.0
                        maskLayer.path = CGPath(roundedRect: contentView.bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
                        contentView.layer?.mask = maskLayer
                    }
                    
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
        
        // checkPermissions() // Disabled to prevent persistent prompting
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.lifecycle.notice("Application will terminate")
        // Save all data before app exits
        FocusViewModel.shared.saveAllData()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Logger.lifecycle.notice("Application reopen requested, hasVisibleWindows: \(flag)")
        
        // If onboarding is not completed, show the onboarding window
        if FocusViewModel.shared.config.isFirstLaunch {
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
            return true
        }
        
        // Otherwise, show the popover from the status bar
        if statusItem?.button != nil {
            if !popover.isShown {
                togglePopover()
            }
        }
        
        // Return false to prevent creating a new window
        return false
    }
    
    private func setupAppIcon() {
        guard let imageURL = resourceURL(name: "MenuBarIcon", ext: "svg"),
              let image = NSImage(contentsOf: imageURL) else { return }
        
        let size = NSSize(width: 512, height: 512)
        let appIcon = NSImage(size: size)
        appIcon.lockFocus()
        NSColor.systemGreen.set()
        let rect = NSRect(origin: .zero, size: size)
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSColor.systemGreen.set()
        rect.fill(using: .sourceIn)
        appIcon.unlockFocus()
        
        NSApp.applicationIconImage = appIcon
    }
    
    func checkPermissions() {
        // let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        // AXIsProcessTrustedWithOptions(options)
    }
    
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: 28)
        if let button = item.button {
            if let imageURL = resourceURL(name: "MenuBarIcon", ext: "svg"),
               let image = NSImage(contentsOf: imageURL) {
                // Use menu bar thickness to determine appropriate icon size
                // This adapts to the user's menu bar size preference
                let thickness = NSStatusBar.system.thickness
                let iconSize = NSSize(width: thickness * 0.75, height: thickness * 0.75)
                image.size = iconSize
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageOnly
                button.imageScaling = .scaleProportionallyDown
            } else {
                button.title = "休息"
            }
            
            button.target = self
            button.action = #selector(togglePopover)
            let rightClick = NSClickGestureRecognizer(target: self, action: #selector(handleRightClick(_:)))
            rightClick.buttonMask = 0x2
            button.addGestureRecognizer(rightClick)
        }
        statusItem = item
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.behavior = .transient
            popover.animates = false  // Disable system animation to avoid flicker
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            
            // Configure window to reduce transparency natively
            if let popoverWindow = popover.contentViewController?.view.window {
                // Reduce window transparency (1.0 = fully opaque, 0.0 = fully transparent)
                popoverWindow.alphaValue = 0.98
                popoverWindow.isOpaque = false
                
                // Set darker background color to match the UI
                // This affects both the arrow and the content area
                popoverWindow.backgroundColor = NSColor(hex: "#1a1a1a")
            }
            
            // Immediately make window key (no flicker since animation is disabled)
            popover.contentViewController?.view.window?.makeKey()
            
            // Trigger animation reset via notification
            NotificationCenter.default.post(name: Notification.Name("PopoverDidShow"), object: nil)
        }
    }

    @objc private func handleHideRequest() {
        NSApplication.shared.windows.first?.orderOut(nil)
    }

    @objc private func handleRightClick(_ sender: Any) {
        guard let button = statusItem?.button else { return }
        let point = NSPoint(x: button.bounds.midX, y: button.bounds.maxY)
        statusMenu.popUp(positioning: nil, at: point, in: button)
    }

    @objc private func quitApp() {
        Logger.lifecycle.notice("User requested quit")
        NSApp.terminate(nil)
    }
    
    @objc private func handleOnboardingCompleted() {
        NSApplication.shared.windows.first?.orderOut(nil)
        if statusItem?.button != nil {
            togglePopover()
        }
    }
    
    @objc private func handleStatusUpdate(_ notification: Notification) {
        guard let button = statusItem?.button,
              let state = notification.userInfo?["state"] as? String else { return }
        
        let color = statusColor(for: state, appearance: button.effectiveAppearance)
        
        if let imageURL = resourceURL(name: "MenuBarIcon", ext: "svg"),
           let baseImage = NSImage(contentsOf: imageURL) {
            
            // Use menu bar thickness to determine appropriate icon size
            let thickness = NSStatusBar.system.thickness
            let iconSize = NSSize(width: thickness * 0.75, height: thickness * 0.75)
            
            if let color = color {
                let tintedImage = baseImage.tinted(with: color)
                tintedImage.size = iconSize
                tintedImage.isTemplate = false
                button.image = tintedImage
                button.contentTintColor = nil
            } else {
                baseImage.size = iconSize
                baseImage.isTemplate = true
                button.image = baseImage
                button.contentTintColor = nil
            }
        }
    }
    
    private func statusColor(for state: String, appearance: NSAppearance?) -> NSColor? {
        switch state {
        case "warning":
            return .systemRed
        case "paused":
            return .systemYellow
        case "idle":
            return .systemGreen
        default:
            return nil
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
            self?.broadcastNotificationSettings()
        }
    }
    
    private func broadcastNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            NotificationCenter.default.post(
                name: .MinTikNotificationStatusChanged,
                object: nil,
                userInfo: ["status": settings.authorizationStatus.rawValue]
            )
        }
    }
}
