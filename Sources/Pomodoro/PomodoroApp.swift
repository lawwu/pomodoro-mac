import AppKit
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    // Show banners even while the app is frontmost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var timer = PomodoroTimer()

    var body: some Scene {
        Window("Pomodoro", id: "main") {
            ContentView()
                .environmentObject(timer)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Timer") {
                Button(timer.isRunning ? "Pause" : "Start") { timer.toggle() }
                    .keyboardShortcut(.space, modifiers: [])
                Button("Reset") { timer.reset() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("Skip") { timer.skip() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(timer)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: timer.phase == .focus ? "timer" : "cup.and.saucer")
                if timer.isRunning || timer.progress > 0 {
                    Text(timer.timeString).monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(timer)
        }
    }
}
