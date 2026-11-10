# RJ GOVII PROXY

An iOS HTTP proxy profile manager starter project.

## Default profile
- Name: drag hs
- Protocol: HTTP
- Host: 62.171.157.60
- Port: 11111
- Authentication: None

## Important
This starter app manages proxy profiles locally and provides a basic TCP reachability check. It does **not** route iPhone traffic or Free Fire traffic through the proxy yet. A system-wide VPN requires a Network Extension target, the appropriate Apple entitlement, provisioning/signing, and a tested tunnel implementation. A proxy host/port alone does not prove that the server supports HTTP CONNECT or UDP.

## Build
The GitHub Actions workflow uses a macOS runner and XcodeGen to build an unsigned iOS app bundle and package it as an IPA artifact. Unsigned packaging does not make the app installable by itself; signing and provisioning are still required.
