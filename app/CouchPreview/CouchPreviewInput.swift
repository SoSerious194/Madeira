import Combine
import GameController
import SwiftUI

/// The preview app's stand-in for LibraryController: turns a game controller,
/// a hardware keyboard (the Mac's, in the Simulator) and an optional launch
/// script into CouchCommands. Held directions repeat, as Big Picture's do.
///
/// Keyboard: arrows move, Return or Space = A, Escape or Delete = B,
/// M or Tab = Start (the guide), Y = Y.
/// Script: `-couchScript "right,right,down,accept"` replays commands at launch.
@MainActor final class CouchPreviewInput: ObservableObject {
    let commands = PassthroughSubject<CouchCommand, Never>()
    @Published private(set) var controllerConnected = false
    private var repeating: (command: CouchCommand, task: Task<Void, Never>)?
    private var observers: [NSObjectProtocol] = []
    private var stickDirection: CouchCommand?

    func start() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated { (note.object as? GCController).map { self?.attach($0) } }
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.controllerConnected = !GCController.controllers().isEmpty }
        })
        GCController.controllers().forEach(attach)
        runScript()
    }

    private func send(_ command: CouchCommand) { commands.send(command) }

    /// Sends a direction now and again while it is held.
    private func press(_ command: CouchCommand, _ pressed: Bool) {
        guard [.up, .down, .left, .right].contains(command) else {
            if pressed { send(command) }
            return
        }
        if pressed {
            repeating?.task.cancel()
            send(command)
            let task = Task {
                try? await Task.sleep(for: .milliseconds(380))
                while !Task.isCancelled {
                    send(command)
                    try? await Task.sleep(for: .milliseconds(110))
                }
            }
            repeating = (command, task)
        } else if repeating?.command == command {
            repeating?.task.cancel()
            repeating = nil
        }
    }

    private func attach(_ controller: GCController) {
        controllerConnected = true
        guard let pad = controller.extendedGamepad else { return }
        let bind: (GCControllerButtonInput, CouchCommand) -> Void = { [weak self] button, command in
            button.pressedChangedHandler = { [weak self] _, _, pressed in
                MainActor.assumeIsolated { self?.press(command, pressed) }
            }
        }
        bind(pad.dpad.up, .up); bind(pad.dpad.down, .down)
        bind(pad.dpad.left, .left); bind(pad.dpad.right, .right)
        bind(pad.buttonA, .accept); bind(pad.buttonB, .back); bind(pad.buttonY, .add)
        bind(pad.buttonMenu, .menu)
        bind(pad.leftShoulder, .tab); bind(pad.rightShoulder, .tab)
        pad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            MainActor.assumeIsolated { self?.stick(x: x, y: y) }
        }
    }

    /// The left stick as a D-pad: past half way in one direction presses it.
    private func stick(x: Float, y: Float) {
        let direction: CouchCommand? = abs(x) < 0.5 && abs(y) < 0.5 ? nil
            : abs(x) > abs(y) ? (x > 0 ? .right : .left) : (y > 0 ? .up : .down)
        guard direction != stickDirection else { return }
        if let old = stickDirection { press(old, false) }
        stickDirection = direction
        if let direction { press(direction, true) }
    }

    /// A hardware key from the preview's onKeyPress (CouchPreviewApp). Key
    /// repeat comes from the system, so keys are sent as they arrive.
    func key(_ key: KeyEquivalent, characters: String) -> Bool {
        let command: CouchCommand? = switch key {
        case .upArrow: .up
        case .downArrow: .down
        case .leftArrow: .left
        case .rightArrow: .right
        case .return, .space: .accept
        case .escape, .delete: .back
        case .tab: .menu
        default: switch characters.lowercased() {
            case "m": .menu
            case "y": .add
            default: nil
            }
        }
        guard let command else { return false }
        send(command)
        return true
    }

    private func runScript() {
        guard let script = UserDefaults.standard.string(forKey: "couchScript") else { return }
        let steps = script.split(separator: ",").compactMap { CouchCommand(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            for step in steps {
                self?.send(step)
                try? await Task.sleep(for: .milliseconds(450))
            }
        }
    }
}
