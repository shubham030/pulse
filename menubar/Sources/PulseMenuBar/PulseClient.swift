import Foundation

// MARK: - Status Model

struct QueuedTimerInfo {
    let duration: Int
    let label: String
}

struct PomodoroInfo {
    let currentCycle: Int
    let totalCycles: Int
    let phase: String
}

struct TimerStatus {
    var status: String = "idle"
    var remaining: Int = 0
    var total: Int = 0
    var label: String = ""
    var paused: Bool = false
    var queue: [QueuedTimerInfo] = []
    var pomodoro: PomodoroInfo? = nil
    var hasNext: Bool { pomodoro != nil || !queue.isEmpty }
}

// MARK: - Client

class PulseClient {
    let host: String
    let port: Int
    private var wsTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var reconnectTimer: Timer?

    var onStatusUpdate: ((TimerStatus) -> Void)?
    var onDisconnect: (() -> Void)?

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    var baseURL: String { "http://\(host):\(port)" }
    var wsURL: String { "ws://\(host):\(port)/ws" }

    // MARK: - WebSocket

    func connect() {
        guard let url = URL(string: wsURL) else {
            print("[ws] Invalid URL: \(wsURL)")
            return
        }
        print("[ws] Connecting to \(wsURL)...")
        wsTask = session.webSocketTask(with: url)
        wsTask?.resume()
        receiveMessage()
    }

    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        wsTask?.cancel(with: .goingAway, reason: nil)
        wsTask = nil
    }

    private func receiveMessage() {
        wsTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()

            case .failure(let error):
                print("[ws] Disconnected: \(error)")
                self?.onDisconnect?()
                self?.scheduleReconnect()
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        var status = TimerStatus()
        status.status = json["status"] as? String ?? "idle"
        status.remaining = json["remaining"] as? Int ?? 0
        status.total = json["total"] as? Int ?? 0
        status.label = json["label"] as? String ?? ""
        status.paused = json["paused"] as? Bool ?? false

        if let queueArray = json["queue"] as? [[String: Any]] {
            status.queue = queueArray.map {
                QueuedTimerInfo(
                    duration: $0["duration"] as? Int ?? 0,
                    label: $0["label"] as? String ?? ""
                )
            }
        }

        if let pomoDict = json["pomodoro"] as? [String: Any] {
            status.pomodoro = PomodoroInfo(
                currentCycle: pomoDict["currentCycle"] as? Int ?? 1,
                totalCycles: pomoDict["totalCycles"] as? Int ?? 4,
                phase: pomoDict["phase"] as? String ?? "focus"
            )
        }

        onStatusUpdate?(status)
    }

    private func scheduleReconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.reconnectTimer?.invalidate()
            self?.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
                self?.connect()
            }
        }
    }

    // MARK: - HTTP

    func post(_ path: String, body: [String: Any]? = nil) {
        guard let url = URL(string: "\(baseURL)\(path)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        session.dataTask(with: request).resume()
    }
}
