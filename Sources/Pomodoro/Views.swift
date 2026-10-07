import SwiftUI

extension Phase {
    var color: Color {
        switch self {
        case .focus: Color(red: 0.93, green: 0.33, blue: 0.29)
        case .shortBreak: Color(red: 0.20, green: 0.70, blue: 0.55)
        case .longBreak: Color(red: 0.29, green: 0.52, blue: 0.90)
        }
    }
}

// MARK: - Main window

struct ContentView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 22) {
            PhasePicker()

            TimerRing(size: 230, lineWidth: 14)

            SessionDots()

            Controls(buttonSize: 52)

            HStack {
                Button("Reset cycle") { timer.resetCycle() }
                Spacer()
                Button {
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 18)
        .frame(width: 360)
        .background(
            LinearGradient(
                colors: [timer.phase.color.opacity(0.18), .clear],
                startPoint: .top, endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: 0.4), value: timer.phase)
    }
}

struct PhasePicker: View {
    @EnvironmentObject private var timer: PomodoroTimer

    var body: some View {
        Picker("Phase", selection: Binding(get: { timer.phase }, set: { timer.select($0) })) {
            ForEach(Phase.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

struct TimerRing: View {
    @EnvironmentObject private var timer: PomodoroTimer
    var size: CGFloat
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(timer.phase.color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(timer.phase.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: timer.progress)
            VStack(spacing: 6) {
                Image(systemName: timer.phase.symbol)
                    .font(.system(size: size * 0.09))
                    .foregroundStyle(timer.phase.color)
                Text(timer.timeString)
                    .font(.system(size: size * 0.24, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                Text(timer.phase.title.uppercased())
                    .font(.system(size: size * 0.05, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SessionDots: View {
    @EnvironmentObject private var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ForEach(0..<max(1, timer.sessionsBeforeLongBreak), id: \.self) { i in
                    Circle()
                        .fill(i < timer.cycleIndex ? Phase.focus.color : Color.secondary.opacity(0.25))
                        .frame(width: 9, height: 9)
                }
            }
            Text("\(timer.completedFocusSessions) sessions completed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct Controls: View {
    @EnvironmentObject private var timer: PomodoroTimer
    var buttonSize: CGFloat

    var body: some View {
        HStack(spacing: 24) {
            RoundButton(systemImage: "arrow.counterclockwise", size: buttonSize * 0.75, help: "Reset") {
                timer.reset()
            }
            RoundButton(
                systemImage: timer.isRunning ? "pause.fill" : "play.fill",
                size: buttonSize,
                tint: timer.phase.color,
                help: timer.isRunning ? "Pause" : "Start"
            ) {
                timer.toggle()
            }
            RoundButton(systemImage: "forward.end.fill", size: buttonSize * 0.75, help: "Skip") {
                timer.skip()
            }
        }
    }
}

struct RoundButton: View {
    var systemImage: String
    var size: CGFloat
    var tint: Color? = nil
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .frame(width: size, height: size)
                .foregroundStyle(tint == nil ? Color.primary : Color.white)
                .background(Circle().fill(tint ?? Color.secondary.opacity(0.15)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// MARK: - Menu bar

struct MenuBarView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            PhasePicker()
            TimerRing(size: 150, lineWidth: 10)
            SessionDots()
            Controls(buttonSize: 40)
            Divider()
            HStack {
                Button("Open Window") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(16)
        .frame(width: 280)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var timer: PomodoroTimer

    var body: some View {
        Form {
            Section("Durations (minutes)") {
                Stepper("Focus: \(timer.focusMinutes)", value: $timer.focusMinutes, in: 1...120)
                Stepper("Short break: \(timer.shortBreakMinutes)", value: $timer.shortBreakMinutes, in: 1...60)
                Stepper("Long break: \(timer.longBreakMinutes)", value: $timer.longBreakMinutes, in: 1...90)
            }
            Section("Cycle") {
                Stepper(
                    "Long break after \(timer.sessionsBeforeLongBreak) sessions",
                    value: $timer.sessionsBeforeLongBreak, in: 2...10
                )
                Toggle("Auto-start next session", isOn: $timer.autoStartNext)
                Toggle("Play sound when a session ends", isOn: $timer.playSound)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }
}
