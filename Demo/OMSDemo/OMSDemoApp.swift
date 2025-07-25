//
//  OMSDemoApp.swift
//  OMSDemo
//
//  Created by Takuto Nakamura on 2024/03/02.
//

import SwiftUI
import OpenMultitouchSupport

@main
struct OMSDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // CRITICAL: Ensure haptics are restored before app termination
        // This prevents the trackpad from being "bricked" if haptics were disabled
        let manager = OMSManager.shared
        if !manager.isHapticEnabled {
            print("⚠️ Restoring haptics before app termination to prevent trackpad issues")
            manager.setHapticEnabled(true)
        }
    }
}
