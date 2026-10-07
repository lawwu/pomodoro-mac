import AppKit
import Foundation
import UserNotifications

enum Phase: String, CaseIterable, Identifiable {
    case focus, shortBreak, longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    var symbol: String {
        switch self {
        case .focus: "brain.head.profile"
        case .shortBreak: "cup.and.saucer"
        case .longBreak: "figure.walk"
        }
    }
}

@MainActor
final class PomodoroTimer: ObservableObject {
    @Published private(set) var phase: Phase = .focus
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusSessions = 0

    // Settings (minutes), persisted in UserDefaults.
    @Published var focusMinutes: Int { didSet { save(); refreshIdleDuration() } }
    @Published var shortBreakMinutes: Int { didSet { save(); refreshIdleDuration() } }
    @Published var longBreakMinutes: Int { didSet { save(); refreshIdleDuration() } }
    @Published var sessionsBeforeLongBreak: Int { didSet { save() } }
    @Published var autoStartNext: Bool { didSet { save() } }
    @Published var playSound: Bool { didSet { save() } }

    private var endDate: Date?
    private var ticker: Timer?
    private let defaults = UserDefaults.standard

    init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            "focusMinutes": 25,
            "shortBreakMinutes": 5,
            "longBreakMinutes": 15,
            "sessionsBeforeLongBreak": 4,
            "autoStartNext": false,
            "playSound": true,
        ])
        focusMinutes = d.integer(forKey: "focusMinutes")
        shortBreakMinutes = d.integer(forKey: "shortBreakMinutes")
        longBreakMinutes = d.integer(forKey: "longBreakMinutes")
        sessionsBeforeLongBreak = d.integer(forKey: "sessionsBeforeLongBreak")
        autoStartNext = d.bool(forKey: "autoStartNext")
        playSound = d.bool(forKey: "playSound")
        remaining = TimeInterval(d.integer(forKey: "focusMinutes") * 60)
        requestNotificationPermission()
    }

    // MARK: - Derived

    func duration(for phase: Phase) -> TimeInterval {
        switch phase {
        case .focus: TimeInterval(focusMinutes * 60)
        case .shortBreak: TimeInterval(shortBreakMinutes * 60)
        case .longBreak: TimeInterval(longBreakMinutes * 60)
        }
    }

    var progress: Double {
        let total = duration(for: phase)
        guard total > 0 else { return 0 }
        return 1 - remaining / total
    }

    var timeString: String {
        let secs = max(0, Int(remaining.rounded(.up)))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    /// Position within the current cycle, e.g. session 2 of 4.
    var cycleIndex: Int { completedFocusSessions % max(1, sessionsBeforeLongBreak) }

    // MARK: - Controls

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(ticker!, forMode: .common)
    }

    func pause() {
        guard isRunning else { return }
        tick()
        stopTicker()
    }

    func reset() {
        stopTicker()
        remaining = duration(for: phase)
    }

    func skip() { advance(completed: false) }

    func select(_ newPhase: Phase) {
        stopTicker()
        phase = newPhase
        remaining = duration(for: newPhase)
    }

    func resetCycle() {
        completedFocusSessions = 0
        select(.focus)
    }

    // MARK: - Internals

    private func tick() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 { advance(completed: true) }
    }

    private func advance(completed: Bool) {
        let wasRunning = isRunning
        stopTicker()
        let finished = phase

        if finished == .focus {
            if completed { completedFocusSessions += 1 }
            let n = max(1, sessionsBeforeLongBreak)
            phase = (completed && completedFocusSessions % n == 0) ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }
        remaining = duration(for: phase)

        if completed {
            notify(finished: finished)
            if playSound { NSSound(named: finished == .focus ? "Glass" : "Hero")?.play() }
        }
        if autoStartNext && (completed || wasRunning) { start() }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        endDate = nil
        isRunning = false
    }

    private func refreshIdleDuration() {
        if !isRunning { remaining = duration(for: phase) }
    }

    private func save() {
        defaults.set(focusMinutes, forKey: "focusMinutes")
        defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes")
        defaults.set(longBreakMinutes, forKey: "longBreakMinutes")
        defaults.set(sessionsBeforeLongBreak, forKey: "sessionsBeforeLongBreak")
        defaults.set(autoStartNext, forKey: "autoStartNext")
        defaults.set(playSound, forKey: "playSound")
    }

    // MARK: - Notifications

    private var notificationsAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    private func requestNotificationPermission() {
        guard notificationsAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(finished: Phase) {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        if finished == .focus {
            content.title = "Focus session complete 🍅"
            content.body = "Time for a \(phase == .longBreak ? "long" : "short") break."
        } else {
            content.title = "Break's over"
            content.body = "Ready to focus again?"
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
