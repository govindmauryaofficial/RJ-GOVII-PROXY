import SwiftUI
import Network

@main
struct RJGoviiProxyApp: App {
    var body: some Scene {
        WindowGroup { ProxyHomeView() }
    }
}

struct ProxyProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var host: String
    var port: String
    var protocolName: String
    var authentication: String = "None"
}

@MainActor
final class ProxyStore: ObservableObject {
    @Published var profiles: [ProxyProfile] = [
        ProxyProfile(name: "drag hs", host: "62.171.157.60", port: "11111", protocolName: "HTTP")
    ]
    @Published var selectedID: UUID?
    @Published var status = "Not tested"
    @Published var isTesting = false
    private var testConnection: NWConnection?

    init() { selectedID = profiles.first?.id }

    func addProfile(host: String, port: String, name: String, protocolName: String) {
        let profile = ProxyProfile(name: name, host: host, port: port, protocolName: protocolName)
        profiles.append(profile)
        selectedID = profile.id
    }

    func remove(_ profile: ProxyProfile) {
        profiles.removeAll { $0.id == profile.id }
        if selectedID == profile.id { selectedID = profiles.first?.id }
    }

    func testSelectedProxy() {
        guard let profile = profiles.first(where: { $0.id == selectedID }),
              let portNumber = UInt16(profile.port),
              let endpointPort = NWEndpoint.Port(rawValue: portNumber) else {
            status = "Select a valid server and port"
            return
        }
        testConnection?.cancel()
        isTesting = true
        status = "Connecting to proxy…"
        let connection = NWConnection(host: NWEndpoint.Host(profile.host), port: endpointPort, using: .tcp)
        testConnection = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                let request = "CONNECT example.com:443 HTTP/1.1\r\nHost: example.com:443\r\nProxy-Connection: Keep-Alive\r\n\r\n"
                connection.send(content: request.data(using: .utf8), completion: .contentProcessed { error in
                    if let error {
                        Task { @MainActor in self?.status = "Send failed: \(error.localizedDescription)"; self?.isTesting = false }
                        connection.cancel()
                        return
                    }
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, error in
                        let response = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        let firstLine = response.components(separatedBy: "\r\n").first ?? ""
                        Task { @MainActor in
                            if let error {
                                self?.status = "Receive failed: \(error.localizedDescription)"
                            } else if firstLine.contains(" 200 ") {
                                self?.status = "HTTP CONNECT supported ✓"
                            } else if firstLine.hasPrefix("HTTP/") {
                                self?.status = "Proxy replied: \(firstLine)"
                            } else {
                                self?.status = "Connected, but no valid HTTP proxy reply"
                            }
                            self?.isTesting = false
                        }
                        connection.cancel()
                    }
                })
            case .failed(let error):
                Task { @MainActor in self?.status = "Connection failed: \(error.localizedDescription)"; self?.isTesting = false }
                connection.cancel()
            case .cancelled:
                break
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
        DispatchQueue.global().asyncAfter(deadline: .now() + 12) { [weak self, weak connection] in
            guard let connection, connection.state != .cancelled else { return }
            Task { @MainActor in
                if self?.isTesting == true {
                    self?.status = "Test timed out"
                    self?.isTesting = false
                }
            }
            connection.cancel()
        }
    }
}

struct ProxyHomeView: View {
    @StateObject private var store = ProxyStore()
    @State private var showAdd = false
    private let red = Color(red: 0.88, green: 0.08, blue: 0.18)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.055, green: 0.06, blue: 0.08).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RJ GOVII").font(.system(size: 14, weight: .bold, design: .rounded)).tracking(3).foregroundStyle(red)
                            Text("PROXY").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(.white)
                            Text("HTTP PROXY PROFILE MANAGER").font(.caption2.weight(.semibold)).tracking(1.5).foregroundStyle(.gray)
                        }.frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("SAVED SERVERS", systemImage: "server.rack").font(.headline).foregroundStyle(.white)
                            ForEach(store.profiles) { profile in
                                Button {
                                    store.selectedID = profile.id
                                    store.status = "Selected: \(profile.host):\(profile.port)"
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(profile.name).font(.headline).foregroundStyle(.white)
                                            Text("\(profile.protocolName) • \(profile.host):\(profile.port)").font(.caption).foregroundStyle(.gray)
                                            Text("Authentication: None").font(.caption2).foregroundStyle(.gray)
                                        }
                                        Spacer()
                                        if store.selectedID == profile.id {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        }
                                    }.padding(14).background(Color.white.opacity(0.07)).clipShape(RoundedRectangle(cornerRadius: 14))
                                }.buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) { store.remove(profile) } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                            Button { showAdd = true } label: {
                                Label("ADD PROXY SERVER", systemImage: "plus")
                                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding()
                                    .background(red).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }.padding(16).background(Color.white.opacity(0.045)).clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 12) {
                            Label("PROXY TEST", systemImage: "network").font(.headline).foregroundStyle(.white)
                            Text(store.status).font(.subheadline).foregroundStyle(.white)
                            Button {
                                store.testSelectedProxy()
                            } label: {
                                HStack {
                                    if store.isTesting { ProgressView().tint(.white) }
                                    Text(store.isTesting ? "TESTING…" : "TEST HTTP CONNECT")
                                }
                                .font(.subheadline.bold()).frame(maxWidth: .infinity).padding()
                                .background(red).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                            }.disabled(store.isTesting)
                            Text("This checks whether the selected server accepts an HTTP CONNECT request. It does not enable a device-wide VPN or route game traffic.")
                                .font(.footnote).foregroundStyle(.orange)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                            .background(Color.white.opacity(0.045)).clipShape(RoundedRectangle(cornerRadius: 20))
                    }.padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) { AddProxyView { name, host, port, proto in
                store.addProfile(host: host, port: port, name: name, protocolName: proto)
            }}
        }
        .preferredColorScheme(.dark)
    }
}

struct AddProxyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var host = ""
    @State private var port = ""
    @State private var proto = "HTTP"
    let onSave: (String, String, String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Profile name", text: $name)
                Picker("Protocol", selection: $proto) {
                    Text("HTTP").tag("HTTP")
                    Text("HTTPS proxy").tag("HTTPS")
                }
                TextField("Server / IP", text: $host).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("Port", text: $port).keyboardType(.numberPad)
                LabeledContent("Authentication", value: "None")
                Section {
                    Text("HTTP CONNECT support is tested separately. HTTPS proxy means TLS to the proxy itself and is not the same as an HTTPS website tunnel.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Proxy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.isEmpty ? "My Proxy" : name, host, port, proto)
                        dismiss()
                    }.disabled(host.isEmpty || Int(port) == nil || !(1...65535).contains(Int(port) ?? 0))
                }
            }
        }
    }
}
