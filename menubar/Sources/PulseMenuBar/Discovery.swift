import Foundation
import Network

class BonjourDiscovery {
    private var browser: NWBrowser?
    private var onFound: (String, Int) -> Void

    init(onFound: @escaping (String, Int) -> Void) {
        self.onFound = onFound
    }

    func start() {
        let params = NWParameters()
        params.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: "_pulse._tcp", domain: nil), using: params)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            for result in results {
                if case .service(let name, _, _, _) = result.endpoint {
                    print("[discovery] Found service: \(name)")
                    self?.resolve(result: result, name: name)
                }
            }
        }

        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[discovery] Browsing for _pulse._tcp...")
            case .failed(let error):
                print("[discovery] Failed: \(error)")
            default:
                break
            }
        }

        browser?.start(queue: .main)
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }

    private func resolve(result: NWBrowser.Result, name: String) {
        let connection = NWConnection(to: result.endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                if let endpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = endpoint {
                    var hostStr: String
                    switch host {
                    case .ipv4(let addr):
                        hostStr = "\(addr)"
                    case .ipv6(let addr):
                        hostStr = "\(addr)"
                    case .name(let name, _):
                        hostStr = name
                    @unknown default:
                        hostStr = "\(host)"
                    }
                    // Strip zone ID suffix (e.g. %en0)
                    if let idx = hostStr.firstIndex(of: "%") {
                        hostStr = String(hostStr[..<idx])
                    }
                    print("[discovery] Resolved: \(hostStr):\(port.rawValue)")
                    DispatchQueue.main.async {
                        self?.onFound(hostStr, Int(port.rawValue))
                    }
                }
                connection.cancel()
            }
        }
        connection.start(queue: .global())
    }
}
