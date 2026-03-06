import AppKit
import Foundation

// MARK: - App Entry

let app = NSApplication.shared
let delegate = PulseAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // No dock icon
app.run()

// MARK: - App Delegate

class PulseAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var client: PulseClient?
    private var discovery: BonjourDiscovery!
    private var currentStatus = TimerStatus()
    private var previousStatus = ""
    private var isConnected = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        statusItem.button?.title = "\u{23F1}"
        buildMenu()

        // Try saved config first, then discover
        if let (host, port) = loadConfig() {
            connectTo(host: host, port: port)
        }

        discovery = BonjourDiscovery { [weak self] host, port in
            guard let self, self.client == nil || !self.isConnected else { return }
            self.connectTo(host: host, port: port)
        }
        discovery.start()
    }

    // MARK: - Connection

    func connectTo(host: String, port: Int) {
        client?.disconnect()
        client = PulseClient(host: host, port: port)

        client?.onStatusUpdate = { [weak self] status in
            DispatchQueue.main.async {
                let prev = self?.previousStatus ?? "idle"
                self?.previousStatus = status.status
                self?.currentStatus = status
                self?.isConnected = true
                self?.updateDisplay()

                // Notify on completion or pause
                if status.status == "completed" && prev != "completed" {
                    self?.sendNotification(
                        title: "Timer Complete",
                        body: status.label.isEmpty ? "Your timer has finished." : "\(status.label) is done."
                    )
                } else if status.status == "paused" && prev == "running" {
                    self?.sendNotification(
                        title: "Timer Paused",
                        body: "\(formatTime(status.remaining)) remaining"
                    )
                } else if status.status == "running" && prev == "idle" {
                    self?.sendNotification(
                        title: status.label.isEmpty ? "Timer Started" : status.label,
                        body: "\(formatTime(status.total)) on the clock"
                    )
                }
            }
        }

        client?.onDisconnect = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.statusItem.button?.title = "\u{23F1} \u{00B7}\u{00B7}\u{00B7}"
                self?.buildMenu()
            }
        }

        client?.connect()
        saveConfig(host: host, port: port)
    }

    // MARK: - Display

    func updateDisplay() {
        guard let button = statusItem.button else { return }

        switch currentStatus.status {
        case "running":
            let time = formatTime(currentStatus.remaining)
            button.title = "\u{23F1} \(time)"
        case "paused":
            let time = formatTime(currentStatus.remaining)
            button.title = "\u{23F8} \(time)"
        case "completed":
            button.title = "\u{2713}"
        default:
            button.title = "\u{23F1}"
        }

        buildMenu()
    }

    // MARK: - Menu

    func buildMenu() {
        let menu = NSMenu()

        if !isConnected {
            menu.addItem(withTitle: "Not connected", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
        } else {
            switch currentStatus.status {
            case "running", "paused":
                // Label
                let label = currentStatus.label.isEmpty ? "Timer" : currentStatus.label
                let time = formatTime(currentStatus.remaining)
                let totalTime = formatTime(currentStatus.total)
                let headerItem = NSMenuItem(title: "\(label) — \(time) / \(totalTime)", action: nil, keyEquivalent: "")
                headerItem.isEnabled = false
                menu.addItem(headerItem)

                // Progress bar
                if currentStatus.total > 0 {
                    let progress = 1.0 - Double(currentStatus.remaining) / Double(currentStatus.total)
                    let barWidth = 20
                    let filled = Int(progress * Double(barWidth))
                    let bar = String(repeating: "\u{2588}", count: filled) + String(repeating: "\u{2591}", count: barWidth - filled)
                    let pct = Int(progress * 100)
                    let progressItem = NSMenuItem(title: "\(bar) \(pct)%", action: nil, keyEquivalent: "")
                    progressItem.isEnabled = false
                    menu.addItem(progressItem)
                }

                // Pomodoro info
                if let pomo = currentStatus.pomodoro {
                    let phase = pomo.phase.capitalized
                    let info = "\(phase) \(pomo.currentCycle)/\(pomo.totalCycles)"
                    let pomoItem = NSMenuItem(title: info, action: nil, keyEquivalent: "")
                    pomoItem.isEnabled = false
                    menu.addItem(pomoItem)
                }

                // Queue info
                if !currentStatus.queue.isEmpty {
                    let queueItem = NSMenuItem(title: "\(currentStatus.queue.count) more in queue", action: nil, keyEquivalent: "")
                    queueItem.isEnabled = false
                    menu.addItem(queueItem)
                }

                menu.addItem(.separator())

                // Controls
                if currentStatus.status == "running" {
                    let pauseItem = NSMenuItem(title: "Pause", action: #selector(pauseTimer), keyEquivalent: "p")
                    pauseItem.target = self
                    menu.addItem(pauseItem)
                } else {
                    let resumeItem = NSMenuItem(title: "Resume", action: #selector(resumeTimer), keyEquivalent: "p")
                    resumeItem.target = self
                    menu.addItem(resumeItem)
                }

                let stopItem = NSMenuItem(title: "Stop", action: #selector(stopTimer), keyEquivalent: "s")
                stopItem.target = self
                menu.addItem(stopItem)

                if currentStatus.hasNext {
                    let skipItem = NSMenuItem(title: "Skip", action: #selector(skipTimer), keyEquivalent: "k")
                    skipItem.target = self
                    menu.addItem(skipItem)
                }

            case "idle":
                let idleItem = NSMenuItem(title: "No timer running", action: nil, keyEquivalent: "")
                idleItem.isEnabled = false
                menu.addItem(idleItem)

                menu.addItem(.separator())

                // Quick start presets
                let presetsMenu = NSMenu()
                for (label, minutes) in [("Focus", 25), ("Short Break", 5), ("Long Break", 15), ("Deep Work", 90)] {
                    let item = NSMenuItem(title: "\(label) (\(minutes)m)", action: #selector(startPreset(_:)), keyEquivalent: "")
                    item.target = self
                    item.tag = minutes
                    item.representedObject = label
                    presetsMenu.addItem(item)
                }
                let presetsItem = NSMenuItem(title: "Start Timer", action: nil, keyEquivalent: "")
                presetsItem.submenu = presetsMenu
                menu.addItem(presetsItem)

                let pomoItem = NSMenuItem(title: "Start Pomodoro", action: #selector(startPomodoro), keyEquivalent: "")
                pomoItem.target = self
                menu.addItem(pomoItem)

            default:
                break
            }

            menu.addItem(.separator())

            // Theme submenu
            let themeMenu = NSMenu()
            for theme in ["dark", "ambient", "warm", "forest", "ocean", "rose"] {
                let item = NSMenuItem(title: theme.capitalized, action: #selector(setTheme(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = theme
                themeMenu.addItem(item)
            }
            let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
            themeItem.submenu = themeMenu
            menu.addItem(themeItem)
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Pulse Menu Bar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc func pauseTimer() {
        client?.post("/pause")
    }

    @objc func resumeTimer() {
        client?.post("/resume")
    }

    @objc func stopTimer() {
        client?.post("/stop")
    }

    @objc func skipTimer() {
        client?.post("/skip")
    }

    @objc func startPreset(_ sender: NSMenuItem) {
        let minutes = sender.tag
        let label = sender.representedObject as? String ?? ""
        client?.post("/timer", body: [
            "duration": minutes * 60,
            "label": label,
            "sound": true,
        ] as [String: Any])
    }

    @objc func startPomodoro() {
        client?.post("/pomodoro", body: [:])
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? String else { return }
        client?.post("/settings", body: ["theme": theme])
    }

    // MARK: - Notifications

    func sendNotification(title: String, body: String) {
        let script = """
            display notification "\(body)" with title "\(title)" sound name "Glass"
            """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    // MARK: - Config

    private var configURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Pulse")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    func saveConfig(host: String, port: Int) {
        let data = try? JSONSerialization.data(withJSONObject: ["host": host, "port": port])
        try? data?.write(to: configURL)
    }

    func loadConfig() -> (String, Int)? {
        guard let data = try? Data(contentsOf: configURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let host = json["host"] as? String, !host.isEmpty,
              let port = json["port"] as? Int else {
            return nil
        }
        return (host, port)
    }
}

// MARK: - Helpers

func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}
