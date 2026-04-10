//
//  WatchConnectionManager.swift
//  Walkify
//
//  Created by Yiğit on 25.02.2026.
//

import Foundation
import WatchConnectivity

/// Apple Watch bağlantı durumunu kontrol eder
@Observable
final class WatchConnectionManager: NSObject {
    var isPaired: Bool = false
    var isReachable: Bool = false
    var isSupported: Bool { WCSession.isSupported() }

    var connectionStatus: String {
        guard isSupported else { return "Desteklenmiyor" }
        guard isPaired else { return "Eşleşmedi" }
        return isReachable ? "Bağlı" : "Eşleşmiş"
    }

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            updateStatus()
        }
    }

    func updateStatus() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        isPaired = session.isPaired
        isReachable = session.isReachable
    }
}

extension WatchConnectionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatus()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
