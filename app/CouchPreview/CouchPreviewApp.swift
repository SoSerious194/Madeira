import SwiftUI

/// Runs Couch mode (app/Madeira/CouchMode) with mock games, so its screens can
/// be designed in the Simulator without Madeira's engine or JIT.
@main
struct CouchPreviewApp: App {
    @StateObject private var store = CouchPreviewStore()
    @StateObject private var input = CouchPreviewInput()
    @FocusState private var keyboardFocus: Bool

    var body: some Scene {
        WindowGroup {
            CouchHomeView(shelves: store.shelves,
                          commands: input.commands.eraseToAnyPublisher(),
                          status: CouchStatus(jitReady: true, controllerConnected: input.controllerConnected),
                          play: store.play, install: store.install,
                          properties: store.properties, guideAction: store.guide)
                .overlay(alignment: .top) {
                    if let banner = store.banner {
                        Text(banner)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.top, 10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.2), value: store.banner)
                .focusable()
                .focusEffectDisabled()
                .focused($keyboardFocus)
                .onKeyPress(phases: [.down, .repeat]) { press in
                    input.key(press.key, characters: press.characters) ? .handled : .ignored
                }
                .onAppear {
                    input.start()
                    keyboardFocus = true
                }
        }
    }
}
