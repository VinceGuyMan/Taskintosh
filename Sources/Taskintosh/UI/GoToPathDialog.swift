import TaskintoshKit
import AppKit

public final class GoToPathDialog: NSWindow {
    private let inputField = NSTextField()
    private let statusLabel = NSTextField()

    public init() {
        let rect = NSRect(x: 0, y: 0, width: 460, height: 210)
        super.init(
            contentRect: rect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Go to Path"
        self.isReleasedWhenClosed = false
        self.center()

        let era = EraManager.shared.activeEra
        let contentView = NSView(frame: rect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = era.theme.surfaceColor.cgColor
        self.contentView = contentView

        // Icon
        let iconView = NSImageView(frame: NSRect(x: 16, y: 150, width: 36, height: 36))
        iconView.image = ProceduralIcons.shared.findIcon(size: 36)
        contentView.addSubview(iconView)

        // Description
        let label = NSTextField(labelWithString: "Enter a macOS path to navigate directly (e.g. ~/Library, /Library, /Volumes):")
        label.frame = NSRect(x: 64, y: 150, width: 380, height: 36)
        label.font = era.theme.font(size: 11)
        label.textColor = era.theme.textColor
        label.isEditable = false
        label.isSelectable = false
        label.lineBreakMode = .byWordWrapping
        contentView.addSubview(label)

        // Input field
        inputField.frame = NSRect(x: 64, y: 116, width: 380, height: 26)
        inputField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        inputField.placeholderString = "~/Library"
        inputField.target = self
        inputField.action = #selector(goClicked)
        contentView.addSubview(inputField)

        // Quick Jump Buttons Row
        let quickLabel = NSTextField(labelWithString: "Quick Access:")
        quickLabel.frame = NSRect(x: 64, y: 84, width: 80, height: 18)
        quickLabel.font = era.theme.boldFont(size: 10)
        quickLabel.textColor = era.theme.textColor
        contentView.addSubview(quickLabel)

        let btnUserLib = createQuickButton(title: "User Library", path: MacOSLocationsService.shared.userLibraryURL.path, x: 148, y: 82, w: 90)
        let btnSysLib = createQuickButton(title: "System Library", path: MacOSLocationsService.shared.systemLibraryURL.path, x: 242, y: 82, w: 96)
        let btnVolumes = createQuickButton(title: "Volumes", path: "/Volumes", x: 342, y: 82, w: 70)
        contentView.addSubview(btnUserLib)
        contentView.addSubview(btnSysLib)
        contentView.addSubview(btnVolumes)

        // Status / error label
        statusLabel.frame = NSRect(x: 64, y: 52, width: 380, height: 18)
        statusLabel.font = era.theme.font(size: 10)
        statusLabel.textColor = NSColor.systemRed
        statusLabel.isEditable = false
        statusLabel.isSelectable = false
        statusLabel.stringValue = ""
        contentView.addSubview(statusLabel)

        // Go / Open Button
        let goButton = NSButton(frame: NSRect(x: 200, y: 14, width: 75, height: 24))
        goButton.title = "Go"
        goButton.bezelStyle = .rounded
        goButton.target = self
        goButton.action = #selector(goClicked)
        goButton.keyEquivalent = "\r"
        contentView.addSubview(goButton)

        // Cancel Button
        let cancelButton = NSButton(frame: NSRect(x: 282, y: 14, width: 75, height: 24))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.keyEquivalent = "\u{1b}"
        contentView.addSubview(cancelButton)

        // Browse Button
        let browseButton = NSButton(frame: NSRect(x: 364, y: 14, width: 80, height: 24))
        browseButton.title = "Browse..."
        browseButton.bezelStyle = .rounded
        browseButton.target = self
        browseButton.action = #selector(browseClicked)
        contentView.addSubview(browseButton)
    }

    private func createQuickButton(title: String, path: String, x: CGFloat, y: CGFloat, w: CGFloat) -> NSButton {
        let btn = NSButton(frame: NSRect(x: x, y: y, width: w, height: 20))
        btn.title = title
        btn.bezelStyle = .inline
        btn.font = NSFont.systemFont(ofSize: 10)
        btn.target = self
        btn.action = #selector(quickButtonClicked(_:))
        btn.identifier = NSUserInterfaceItemIdentifier(path)
        return btn
    }

    @objc private func quickButtonClicked(_ sender: NSButton) {
        if let path = sender.identifier?.rawValue {
            inputField.stringValue = path
            statusLabel.stringValue = ""
        }
    }

    @objc private func goClicked() {
        let raw = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            statusLabel.stringValue = "Please enter a path."
            return
        }

        let expanded = NSString(string: raw).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        if FileManager.default.fileExists(atPath: url.path) {
            self.close()
            MacOSLocationsService.shared.openURL(url)
        } else {
            statusLabel.stringValue = "Path does not exist: \(raw)"
        }
    }

    @objc private func cancelClicked() {
        self.close()
    }

    @objc private func browseClicked() {
        MacOSLocationsService.shared.openFolderDialog { [weak self] chosenURL in
            if let path = chosenURL?.path {
                self?.inputField.stringValue = path
                self?.statusLabel.stringValue = ""
            }
        }
    }
}
