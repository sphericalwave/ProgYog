//
//  KeyboardDismiss.swift
//  ProgYog
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

enum KeyboardDismiss {
    /// Attaches a tap recognizer to the key window that ends editing on
    /// any tap. `cancelsTouchesInView = false` so NavigationLinks,
    /// buttons, swipes, etc. still receive their touches normally.
    @MainActor
    static func installWindowTapRecognizer() {
        #if os(iOS)
        DispatchQueue.main.async {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
            else { return }
            let recognizer = UITapGestureRecognizer(
                target: window,
                action: #selector(UIView.endEditing(_:))
            )
            recognizer.cancelsTouchesInView = false
            recognizer.requiresExclusiveTouchType = false
            window.addGestureRecognizer(recognizer)
        }
        #endif
    }
}

extension View {
    /// Adds a trailing "Done" button to the keyboard accessory bar that
    /// dismisses whatever field is focused. Resigns first responder globally,
    /// so no per-field `@FocusState` is needed. Apply once at a hierarchy root
    /// (`RootView`) and on each modal sheet that contains text input, since a
    /// sheet presents in its own hierarchy and won't inherit the root's.
    func keyboardDoneToolbar() -> some View {
        #if os(iOS)
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
        #else
        self
        #endif
    }
}
