import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(options: [String: NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        // Deliberately fail closed until a tested TCP/UDP packet-to-proxy
        // transport engine is integrated. Starting an empty tunnel would
        // black-hole the device's network traffic.
        let error = NSError(
            domain: "com.govindmaurya.rjgovii-proxy",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey:
                "Tunnel transport is not configured yet. No device traffic was changed."]
        )
        completionHandler(error)
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
