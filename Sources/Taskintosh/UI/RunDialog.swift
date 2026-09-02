import AppKit
import TaskintoshKit

public final class RunDialog: NSWindow {
    private let inputField = NSTextField()

    public init() {
        let rect = NSRect(x: 0, y: 0, width: 400, height: 160)
        super.init(
            contentRect: rect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Run"
        self.isReleasedWhenClosed = false
        self.center()

        let era = EraManager.shared.activeEra
        let contentView = NSView(frame: rect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = era.theme.surfaceColor.cgColor
        self.contentView = contentView

        // Icon
        let iconView = NSImageView(frame: NSRect(x: 16, y: 100, width: 36, height: 36))
        iconView.image = ProceduralIcons.shared.runIcon(size: 36)
        contentView.addSubview(iconView)

        // Description
        let label = NSTextField(labelWithString: "Type the name of a program, folder, document, or Internet resource, and Taskintosh will open it for you.")
        label.frame = NSRect(x: 64, y: 92, width: 316, height: 48)
        label.font = era.theme.font(size: 11)
        label.textColor = era.theme.textColor
        label.isEditable = false
        label.isSelectable = false
        label.lineBreakMode = .byWordWrapping
        contentView.addSubview(label)

        // "Open:" label
        let openLabel = NSTextField(labelWithString: "Open:")
        openLabel.frame = NSRect(x: 16, y: 56, width: 44, height: 20)
        openLabel.font = era.theme.font(size: 11)
        openLabel.textColor = era.theme.textColor
        contentView.addSubview(openLabel)

        // Input field
        inputField.frame = NSRect(x: 64, y: 54, width: 316, height: 24)
        inputField.font = era.theme.font(size: 11)
        inputField.target = self
        inputField.action = #selector(okClicked)
        contentView.addSubview(inputField)

        // OK Button
        let okButton = NSButton(frame: NSRect(x: 140, y: 14, width: 75, height: 24))
        okButton.title = "OK"
        okButton.bezelStyle = .rounded
        okButton.target = self
        okButton.action = #selector(okClicked)
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)

        // Cancel Button
        let cancelButton = NSButton(frame: NSRect(x: 222, y: 14, width: 75, height: 24))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.keyEquivalent = "\u{1b}"
        contentView.addSubview(cancelButton)

        // Browse Button
        let browseButton = NSButton(frame: NSRect(x: 305, y: 14, width: 75, height: 24))
        browseButton.title = "Browse..."
        browseButton.bezelStyle = .rounded
        browseButton.target = self
        browseButton.action = #selector(browseClicked)
        contentView.addSubview(browseButton)
    }

    @objc private func okClicked() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if text.hasPrefix("http://") || text.hasPrefix("https://"), let url = URL(string: text) {
            NSWorkspace.shared.open(url)
        } else if FileManager.default.fileExists(atPath: text) {
            NSWorkspace.shared.open(URL(fileURLWithPath: text))
        } else {
            // Check in /Applications or run terminal command
            let appPath = "/Applications/\(text).app"
            let sysAppPath = "/System/Applications/\(text).app"
            if FileManager.default.fileExists(atPath: appPath) {
                NSWorkspace.shared.open(URL(fileURLWithPath: appPath))
            } else if FileManager.default.fileExists(atPath: sysAppPath) {
                NSWorkspace.shared.open(URL(fileURLWithPath: sysAppPath))
            } else {
                // Execute command
                let task = Process()
                task.launchPath = "/bin/zsh"
                task.arguments = ["-c", text]
                try? task.run()
            }
        }

        self.close()
    }

    @objc private func cancelClicked() {
        self.close()
    }

    @objc private func browseClicked() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            inputField.stringValue = url.path
        }
    }
}
