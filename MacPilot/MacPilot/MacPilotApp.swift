//
//  MacPilotApp.swift
//  MacPilot
//
//  MacPilot project - RetroByteLab.
//

import SwiftUI

@main
struct MacPilotApp: App {
    // Shared with the in-window Settings page.
    // An absent key leaves the assistant off, including for existing users.
    @AppStorage("menuBarAssistantEnabled") private var menuBarAssistantEnabled = false
    @StateObject private var quickActions = MenuBarQuickActionState()

    var body: some Scene {
        WindowGroup("MacPilot", id: "main") {
            ContentView()
        }

        Settings {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Menu Bar Assistant", isOn: $menuBarAssistantEnabled)
                Text("Access MacPilot quickly from your Mac's menu bar.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 360)
        }

        // SwiftUI owns one status item and inserts/removes it with the preference.
        // This scene owns no AI controller, inference process, or command history.
        MenuBarExtra(isInserted: $menuBarAssistantEnabled) {
            MenuBarAssistantView(quickActions: quickActions)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "command")
                Text("MacPilot")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("MacPilot menu bar assistant")
        }
        .menuBarExtraStyle(.window)
    }
}

/// Keep a single in-flight launch across panel closures and preference toggles.
/// Only the latest short result is retained; no model or command history is owned here.
@MainActor
private final class MenuBarQuickActionState: ObservableObject {
    @Published private(set) var activeTarget: MacPilotQuickAction?
    @Published private(set) var message: String?
    @Published private(set) var didFail = false

    func launch(_ target: MacPilotQuickAction) {
        guard activeTarget == nil else { return }
        activeTarget = target
        message = nil
        didFail = false
        // Closing or disabling the panel does not cancel a requested app launch.
        Task { @MainActor in
            defer { activeTarget = nil }
            switch await MacPilotAppLauncher.launch(target) {
            case .success(let confirmation):
                message = confirmation
            case .failure(let failure):
                message = failure.localizedDescription
                didFail = true
            }
        }
    }
}

private struct MenuBarAssistantView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var quickActions: MenuBarQuickActionState
    @ObservedObject private var commandSession = MacPilotCommandSession.shared
    @State private var command = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("MacPilot", systemImage: "paperplane")
                .font(.headline)
            aiCommandArea
            Divider()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(MacPilotQuickAction.allCases, id: \.self) { target in
                    Button {
                        quickActions.launch(target)
                    } label: {
                        Label(target.displayName, systemImage: symbol(for: target))
                            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .disabled(quickActions.activeTarget != nil)
                }
            }
            if let target = quickActions.activeTarget {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Opening \(target.displayName)…")
                }
                .font(.callout)
                .accessibilityElement(children: .combine)
            } else if let message = quickActions.message {
                Label(message, systemImage: quickActions.didFail ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(quickActions.didFail ? Color.red : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            Divider()
            Button(commandSession.requiresApproval ? "Review Plan in Main MacPilot Window" : "Open Main MacPilot Window") {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var aiCommandArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Try Open Chrome and Calculator", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("AI application command")
                    .onSubmit { submitCommand() }
                    .disabled(commandSession.isBusy)
                Button("Send") { submitCommand() }
                    .disabled(commandSession.isBusy || command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            HStack(alignment: .top, spacing: 8) {
                if commandSession.isProcessing {
                    ProgressView().controlSize(.small)
                        .accessibilityLabel("Processing command")
                }
                ScrollView {
                    Text(commandSession.errorMessage ?? commandSession.status)
                        .font(.callout)
                        .foregroundStyle(commandSession.errorMessage == nil ? Color.secondary : Color.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 70)
            }
            if commandSession.requiresApproval {
                Text("Proposed actions — approval required")
                    .font(.caption).fontWeight(.semibold)
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(commandSession.proposedActions.enumerated()), id: \.element.id) { index, action in
                            Label("\(index + 1). Open \(action.applicationName)",
                                  systemImage: action.isResolved ? "app" : "exclamationmark.triangle")
                                .font(.callout)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 110)
                Text("Review and approve in the main window. Nothing opens automatically.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if commandSession.isBusy {
                Button(commandSession.cancellationRequested ? "Cancellation Requested" : "Cancel Command") {
                    commandSession.cancel()
                }
                .disabled(!commandSession.canCancel)
            }
        }
    }

    private func submitCommand() {
        guard !commandSession.isBusy,
              !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        commandSession.submit(command)
    }

    private func symbol(for target: MacPilotQuickAction) -> String {
        switch target {
        case .safari: return "safari"
        case .chrome: return "globe"
        case .calculator: return "plus.forwardslash.minus"
        case .notes: return "note.text"
        }
    }
}
