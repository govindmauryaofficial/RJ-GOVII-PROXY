# VPN implementation status

## Completed
- SwiftUI proxy profile manager
- Default HTTP proxy profile: 62.171.157.60:11111
- HTTP CONNECT reachability test (the app displayed "HTTP CONNECT supported")
- macOS GitHub Actions unsigned IPA packaging

## Added in this change
- XcodeGen Packet Tunnel extension target scaffold
- NEPacketTunnelProvider entry point
- Packet Tunnel entitlement declaration
- Fail-closed startup: the extension refuses to start until a real packet transport is integrated

## Not implemented yet
- TCP packet-to-HTTP-CONNECT transport (requires a maintained tun2socks/TCP stack integration)
- UDP transport (the supplied HTTP CONNECT test does not establish UDP support)
- VPN profile creation and start/stop UI in the host app
- Apple Network Extension entitlement approval, provisioning profile and signed distribution

## Important
An entitlement file in source does not grant Apple's entitlement. The app's App ID must be approved for Network Extensions and the provisioning profile must contain it. Do not claim the VPN works until signed installation and end-to-end TCP/UDP routing tests pass. The extension intentionally does not install routes or consume packets yet, to avoid cutting off the phone's connectivity.
