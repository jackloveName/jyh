import SwiftUI
import UIKit

enum JYKeyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    func jyKeyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    JYKeyboard.dismiss()
                }
            }
        }
    }

    func jyDismissKeyboardOnBackgroundTap() -> some View {
        background(WindowKeyboardDismissInstaller())
    }
}

private struct WindowKeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> DismissKeyboardView {
        DismissKeyboardView()
    }

    func updateUIView(_ uiView: DismissKeyboardView, context: Context) {}
}

private final class DismissKeyboardView: UIView {
    private weak var installedWindow: UIWindow?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else { return }
        guard installedWindow !== window else { return }
        removeInstalledGesture()
        if window.gestureRecognizers?.contains(where: { $0.name == "JYKeyboardDismissTap" }) == true {
            installedWindow = window
            return
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.cancelsTouchesInView = false
        gesture.name = "JYKeyboardDismissTap"
        window.addGestureRecognizer(gesture)
        installedWindow = window
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let window else { return }
        guard let responder = firstResponder(in: window) else { return }
        let point = gesture.location(in: window)
        let hitView = window.hitTest(point, with: nil)

        if let responderView = responder as? UIView,
           hitView === responderView || hitView?.isDescendant(of: responderView) == true {
            return
        }
        // Web inputs are handled by the injected H5 keyboard-dismiss script.
        if isInsideWebView(hitView) { return }
        JYKeyboard.dismiss()
    }

    private func firstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let responder = firstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }

    private func isInsideWebView(_ view: UIView?) -> Bool {
        var current = view
        while let candidate = current {
            if String(describing: type(of: candidate)).hasPrefix("WKWebView") {
                return true
            }
            current = candidate.superview
        }
        return false
    }

    private func removeInstalledGesture() {
        guard let window = installedWindow else { return }
        window.gestureRecognizers?
            .filter { $0.name == "JYKeyboardDismissTap" }
            .forEach { window.removeGestureRecognizer($0) }
        self.installedWindow = nil
    }

    deinit {
        removeInstalledGesture()
    }
}
