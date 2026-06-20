//
//  ShakeListener.swift
//  ProgYog
//
//  Global device-shake detector. Drops a 0-size UIKit responder into the
//  view tree; the VC overrides motionEnded and posts a Notification.
//  Decoupled lifetime — observers can be installed anywhere in SwiftUI
//  without sharing a parent with the listener.
//

import SwiftUI

extension Notification.Name {
    static let deviceDidShake = Notification.Name("ProgYog.deviceDidShake")
}

#if os(iOS)
import UIKit

private final class ShakeVC: UIViewController {
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

struct ShakeListener: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { ShakeVC() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {}
}
#endif

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        #if os(iOS)
        background(ShakeListener().frame(width: 0, height: 0))
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                action()
            }
        #else
        self
        #endif
    }
}
