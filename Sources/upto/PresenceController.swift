import Foundation
import Observation
import SwiftUI
import UptoCore

// Bridges the IPC client actor to SwiftUI on the main actor.
@MainActor
@Observable
final class PresenceController {
    private(set) var state: ConnectionState = .idle
    private(set) var lastError: String?

    private let client = DiscordIPCClient()
    private var listenTask: Task<Void, Never>?

    init() {
        listenTask = Task { [weak self] in
            guard let client = self?.client else { return }
            let events = await client.stateUpdates()
            for await event in events {
                guard let self else { return }
                switch event {
                case .stateChanged(let newState):
                    self.state = newState
                case .rpcError(let code, let message):
                    self.lastError = "Discord error \(code): \(message)"
                case .activityAcknowledged:
                    self.lastError = nil
                }
            }
        }
    }

    func connect(applicationID: String) {
        lastError = nil
        Task { await client.connect(applicationID: applicationID) }
    }

    func disconnect() {
        Task { await client.disconnect() }
    }

    func apply(_ activity: Activity) {
        submit(activity)
    }

    func clearPresence() {
        submit(nil)
    }

    var userDisplayName: String? {
        if case .ready(let user) = state {
            return user?.globalName ?? user?.username
        }
        return nil
    }

    private func submit(_ activity: Activity?) {
        Task {
            do {
                try await client.setActivity(activity)
            } catch let error as ActivityValidationError {
                lastError = error.issues.first?.message ?? "The presence is not valid."
            } catch {
                lastError = "Could not update the presence."
            }
        }
    }

    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    var isBusy: Bool {
        switch state {
        case .scanning, .backoff, .ready:
            return true
        case .idle, .failed:
            return false
        }
    }

    var statusText: String {
        switch state {
        case .idle:
            return "Not connected"
        case .scanning:
            return "Looking for Discord"
        case .ready(let user):
            if let name = user?.globalName ?? user?.username {
                return "Connected as \(name)"
            }
            return "Connected"
        case .backoff(_, .noSocketFound):
            return "Discord not found, retrying"
        case .backoff:
            return "Reconnecting"
        case .failed(.invalidApplicationID):
            return "Invalid application ID"
        }
    }

    var statusColor: Color {
        switch state {
        case .idle:
            return .gray
        case .scanning:
            return .yellow
        case .ready:
            return .green
        case .backoff:
            return .orange
        case .failed:
            return .red
        }
    }
}
