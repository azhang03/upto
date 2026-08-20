import AppKit
import SwiftUI

// Applies window settings that SwiftUI does not expose. The view draws
// nothing. Background dragging makes the custom header strip behave
// like a title bar, and the title bar container moves down so the
// close, minimize, and zoom buttons sit centered on the header. A
// toolbar cannot do this here: any toolbar on this window covers the
// custom header on macOS 26.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfiguratorView {
        ConfiguratorView()
    }

    func updateNSView(_ nsView: ConfiguratorView, context: Context) {}

    final class ConfiguratorView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.isMovableByWindowBackground = true
            window.titlebarSeparatorStyle = .none
            centerTrafficLights()
            NotificationCenter.default.removeObserver(self)
            for name in [
                NSWindow.didResizeNotification,
                NSWindow.didBecomeKeyNotification,
                NSWindow.didExitFullScreenNotification,
            ] {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(windowChanged),
                    name: name,
                    object: window
                )
            }
        }

        @objc private func windowChanged() {
            centerTrafficLights()
        }

        // The system centers the buttons in a short title bar strip at
        // the very top. Moving the strip down centers them on the
        // header. The move repeats after every resize because the
        // system puts the strip back. The decoration view draws the
        // title bar edge line, which has no place on the header, so it
        // hides.
        private func centerTrafficLights() {
            guard let window,
                  let close = window.standardWindowButton(.closeButton),
                  let titlebar = close.superview,
                  let container = titlebar.superview,
                  let frameView = container.superview
            else { return }
            for view in container.subviews
            where String(describing: type(of: view)).contains("TitlebarDecoration") {
                view.isHidden = true
            }
            let barHeight = container.frame.height
            let offset = Theme.Metrics.headerHeight / 2 - barHeight / 2
            guard offset > 0 else { return }
            let target = frameView.bounds.height - barHeight - offset
            if container.frame.origin.y != target {
                container.frame.origin.y = target
            }
            let buttons = [close,
                           window.standardWindowButton(.miniaturizeButton),
                           window.standardWindowButton(.zoomButton)].compactMap { $0 }
            let shift = Theme.Metrics.trafficLightLeading - close.frame.origin.x
            if shift != 0 {
                for button in buttons {
                    button.frame.origin.x += shift
                }
            }
        }
    }
}
