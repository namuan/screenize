import SwiftUI

struct OnboardingView: View {
    @StateObject private var permissionsManager = PermissionsManager()
    @StateObject private var accessibilityStatus = AccessibilityStatus()
    @State private var isRefreshing = false

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            permissionsList
            Divider()
            footerSection
        }
        .frame(width: 520, height: 580)
        .onAppear {
            refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Welcome to Screenize")
                .font(.title)
                .fontWeight(.bold)

            Text("Screenize needs a few permissions to record your screen and generate smart annotations.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
    }

    private var permissionsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "rectangle.dashed.badge.record",
                    title: "Screen Recording",
                    description: "Required to capture your screen, windows, and applications.",
                    status: screenCaptureStatus,
                    isRequired: true,
                    action: { await requestScreenCapturePermission() },
                    openSettingsAction: { openScreenRecordingSettings() }
                )

                PermissionRow(
                    icon: "keyboard",
                    title: "Input Monitoring",
                    description: "Required to track keyboard shortcuts for smart annotations and keystroke overlays.",
                    status: inputMonitoringStatus,
                    isRequired: true,
                    action: { await requestInputMonitoringPermission() },
                    openSettingsAction: { openInputMonitoringSettings() }
                )

                PermissionRow(
                    icon: "mic",
                    title: "Microphone",
                    description: "Required to record audio commentary during screen recordings.",
                    status: microphoneStatus,
                    isRequired: true,
                    action: { await requestMicrophonePermission() },
                    openSettingsAction: { openMicrophoneSettings() }
                )

                PermissionRow(
                    icon: "figure.walk.circle",
                    title: "Accessibility",
                    description: "Required to detect UI elements (buttons, menus) for contextual annotations.",
                    status: accessibilityStatus.status,
                    isRequired: true,
                    action: { await requestAccessibilityPermission() },
                    openSettingsAction: { openAccessibilitySettings() }
                )
            }
            .padding(24)
        }
    }

    private var footerSection: some View {
        HStack(spacing: 16) {
            Button(action: refreshPermissions) {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
            .help("Refresh permission status")

            Spacer()

            if !missingRequiredPermissions.isEmpty {
                Text("Grant \(missingRequiredPermissions.joined(separator: ", ")) to continue.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Continue") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!hasRequiredPermissions)
        }
        .padding(24)
    }

    // MARK: - Status Computed Properties

    private var hasRequiredPermissions: Bool {
        permissionsManager.hasScreenCapturePermission
            && permissionsManager.hasInputMonitoringPermission
            && permissionsManager.hasMicrophonePermission
            && accessibilityStatus.status == .granted
    }

    private var missingRequiredPermissions: [String] {
        var missing: [String] = []

        if !permissionsManager.hasScreenCapturePermission {
            missing.append("Screen Recording")
        }

        if !permissionsManager.hasInputMonitoringPermission {
            missing.append("Input Monitoring")
        }

        if !permissionsManager.hasMicrophonePermission {
            missing.append("Microphone")
        }

        if accessibilityStatus.status != .granted {
            missing.append("Accessibility")
        }

        return missing
    }

    private var screenCaptureStatus: PermissionRow.Status {
        permissionsManager.hasScreenCapturePermission ? .granted : .denied
    }

    private var microphoneStatus: PermissionRow.Status {
        switch permissionsManager.microphonePermission {
        case .granted: return .granted
        case .denied, .restricted: return .denied
        case .unknown: return .unknown
        }
    }

    private var inputMonitoringStatus: PermissionRow.Status {
        switch permissionsManager.inputMonitoringPermission {
        case .granted: return .granted
        case .denied, .restricted: return .denied
        case .unknown: return .unknown
        }
    }

    // MARK: - Permission Actions

    private func refreshPermissions() {
        isRefreshing = true
        permissionsManager.checkCurrentPermissions()
        accessibilityStatus.checkStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
    }

    private func requestScreenCapturePermission() async {
        _ = await permissionsManager.requestScreenCapturePermission()
        refreshPermissions()
    }

    private func requestMicrophonePermission() async {
        _ = await permissionsManager.requestMicrophonePermission()
        refreshPermissions()
    }

    private func requestInputMonitoringPermission() async {
        permissionsManager.requestInputMonitoringPermission()
        try? await Task.sleep(nanoseconds: 500_000_000)
        refreshPermissions()
    }

    private func requestAccessibilityPermission() async {
        accessibilityStatus.requestPermission()
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        refreshPermissions()
    }

    // MARK: - System Settings URLs

    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: Status
    let isRequired: Bool
    let action: () async -> Void
    let openSettingsAction: () -> Void

    @State private var isRequesting = false

    enum Status {
        case unknown
        case granted
        case denied
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(statusColor)
                .frame(width: 40, height: 40)
                .background(statusColor.opacity(0.15))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)

                    if isRequired {
                        Text("Required")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Status & Action
            HStack(spacing: 8) {
                statusBadge

                Button(action: {
                    Task {
                        isRequesting = true
                        await action()
                        isRequesting = false
                    }
                }) {
                    if isRequesting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    } else {
                        Text(buttonLabel)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(status == .granted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(status == .granted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch status {
        case .granted: return .green
        case .denied: return .red
        case .unknown: return .orange
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(statusText)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusIcon: String {
        switch status {
        case .granted: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private var statusText: String {
        switch status {
        case .granted: return "Granted"
        case .denied: return "Not Granted"
        case .unknown: return "Unknown"
        }
    }

    private var buttonLabel: String {
        switch status {
        case .granted: return "Granted"
        case .denied, .unknown: return "Allow"
        }
    }
}

// MARK: - Accessibility Status Observable

@MainActor
final class AccessibilityStatus: ObservableObject {
    @Published var status: PermissionRow.Status = .unknown

    init() {
        checkStatus()
    }

    func checkStatus() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        status = trusted ? .granted : .denied
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        // Re-check after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkStatus()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
