import AppKit
import TaskintoshKit

public final class EraManagerWindow: NSWindow, NSTableViewDataSource, NSTableViewDelegate {
    private let tableView = NSTableView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let periodLabel = NSTextField(labelWithString: "")
    private let versionLabel = NSTextField(labelWithString: "")
    private let authorLabel = NSTextField(labelWithString: "")
    private let descLabel = NSTextField(labelWithString: "")
    private let activateButton = NSButton()
    private let accessibilityStatusLabel = NSTextField(labelWithString: "")

    public init() {
        let rect = NSRect(x: 0, y: 0, width: 560, height: 440)
        super.init(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        self.title = "Taskintosh Era Manager & Properties"
        self.isReleasedWhenClosed = false
        self.center()

        let contentView = NSView(frame: rect)
        self.contentView = contentView

        // Header Title
        let header = NSTextField(labelWithString: "Desktop History & Era Packs")
        header.frame = NSRect(x: 20, y: 398, width: 400, height: 24)
        header.font = NSFont.boldSystemFont(ofSize: 15)
        contentView.addSubview(header)

        // Subtitle
        let subheader = NSTextField(labelWithString: "“The wrong taskbar for the right computer.”")
        subheader.frame = NSRect(x: 20, y: 378, width: 400, height: 18)
        subheader.font = NSFont.systemFont(ofSize: 11)
        subheader.textColor = .secondaryLabelColor
        contentView.addSubview(subheader)

        // Table scroll view on left
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 130, width: 220, height: 240))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("EraCol"))
        col.title = "Installed Eras"
        col.width = 200
        tableView.addTableColumn(col)
        tableView.headerView = NSTableHeaderView()
        tableView.dataSource = self
        tableView.delegate = self
        scroll.documentView = tableView
        contentView.addSubview(scroll)

        // Details on right
        let detailBox = NSBox(frame: NSRect(x: 250, y: 130, width: 290, height: 240))
        detailBox.title = "Era Information"
        detailBox.contentView?.addSubview(nameLabel)
        detailBox.contentView?.addSubview(periodLabel)
        detailBox.contentView?.addSubview(versionLabel)
        detailBox.contentView?.addSubview(authorLabel)
        detailBox.contentView?.addSubview(descLabel)
        detailBox.contentView?.addSubview(activateButton)

        nameLabel.frame = NSRect(x: 12, y: 180, width: 260, height: 20)
        nameLabel.font = NSFont.boldSystemFont(ofSize: 13)

        periodLabel.frame = NSRect(x: 12, y: 160, width: 260, height: 16)
        periodLabel.font = NSFont.systemFont(ofSize: 11)
        periodLabel.textColor = .secondaryLabelColor

        versionLabel.frame = NSRect(x: 12, y: 140, width: 260, height: 16)
        versionLabel.font = NSFont.systemFont(ofSize: 11)

        authorLabel.frame = NSRect(x: 12, y: 120, width: 260, height: 16)
        authorLabel.font = NSFont.systemFont(ofSize: 11)

        descLabel.frame = NSRect(x: 12, y: 45, width: 260, height: 70)
        descLabel.font = NSFont.systemFont(ofSize: 11)
        descLabel.lineBreakMode = .byWordWrapping

        activateButton.frame = NSRect(x: 12, y: 10, width: 120, height: 26)
        activateButton.title = "Activate Era"
        activateButton.bezelStyle = .rounded
        activateButton.target = self
        activateButton.action = #selector(activateClicked)

        contentView.addSubview(detailBox)

        // Buttons below table
        let importButton = NSButton(frame: NSRect(x: 20, y: 92, width: 110, height: 26))
        importButton.title = "Import Era..."
        importButton.bezelStyle = .rounded
        importButton.target = self
        importButton.action = #selector(importClicked)
        contentView.addSubview(importButton)

        let reloadButton = NSButton(frame: NSRect(x: 135, y: 92, width: 105, height: 26))
        reloadButton.title = "Reload Eras"
        reloadButton.bezelStyle = .rounded
        reloadButton.target = self
        reloadButton.action = #selector(reloadClicked)
        contentView.addSubview(reloadButton)

        // Bottom section: System Integrations & Helpers
        let helperBox = NSBox(frame: NSRect(x: 20, y: 12, width: 520, height: 74))
        helperBox.title = "macOS Integration & Dock Helper"

        let hideDockBtn = NSButton(frame: NSRect(x: 12, y: 14, width: 150, height: 26))
        hideDockBtn.title = "Auto-Hide macOS Dock"
        hideDockBtn.bezelStyle = .rounded
        hideDockBtn.target = self
        hideDockBtn.action = #selector(hideDockClicked)
        helperBox.contentView?.addSubview(hideDockBtn)

        let restoreDockBtn = NSButton(frame: NSRect(x: 168, y: 14, width: 150, height: 26))
        restoreDockBtn.title = "Restore macOS Dock"
        restoreDockBtn.bezelStyle = .rounded
        restoreDockBtn.target = self
        restoreDockBtn.action = #selector(restoreDockClicked)
        helperBox.contentView?.addSubview(restoreDockBtn)

        let a11yBtn = NSButton(frame: NSRect(x: 324, y: 14, width: 180, height: 26))
        a11yBtn.title = "Accessibility Settings..."
        a11yBtn.bezelStyle = .rounded
        a11yBtn.target = self
        a11yBtn.action = #selector(a11yClicked)
        helperBox.contentView?.addSubview(a11yBtn)

        accessibilityStatusLabel.frame = NSRect(x: 12, y: 44, width: 490, height: 16)
        accessibilityStatusLabel.font = NSFont.systemFont(ofSize: 10)
        helperBox.contentView?.addSubview(accessibilityStatusLabel)

        contentView.addSubview(helperBox)

        updateAccessibilityStatus()
        updateSelectedEraDetails()
    }

    public func updateAccessibilityStatus() {
        let trusted = WindowAccessibilityBridge.shared.isAccessibilityTrusted
        if trusted {
            accessibilityStatusLabel.stringValue = "Accessibility: Enabled (Window-level tracking active)"
            accessibilityStatusLabel.textColor = .systemGreen
        } else {
            accessibilityStatusLabel.stringValue = "Accessibility: Disabled (App-level mode active, zero permissions needed)"
            accessibilityStatusLabel.textColor = .secondaryLabelColor
        }
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return EraManager.shared.availableEras.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let eras = EraManager.shared.availableEras
        guard row < eras.count else { return nil }
        let era = eras[row]
        let isActive = (era.manifest.id == EraManager.shared.activeEra.manifest.id)

        let cell = NSTextField(labelWithString: isActive ? "★ \(era.manifest.name)" : era.manifest.name)
        cell.font = isActive ? NSFont.boldSystemFont(ofSize: 12) : NSFont.systemFont(ofSize: 12)
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        updateSelectedEraDetails()
    }

    private func updateSelectedEraDetails() {
        let row = tableView.selectedRow >= 0 ? tableView.selectedRow : 0
        let eras = EraManager.shared.availableEras
        guard row < eras.count else { return }
        let era = eras[row]

        nameLabel.stringValue = era.manifest.name
        periodLabel.stringValue = "Era: \(era.manifest.eraPeriod)"
        versionLabel.stringValue = "Version: \(era.manifest.version)"
        authorLabel.stringValue = "Author: \(era.manifest.author)"
        descLabel.stringValue = era.manifest.description

        let isActive = (era.manifest.id == EraManager.shared.activeEra.manifest.id)
        activateButton.isEnabled = !isActive
        activateButton.title = isActive ? "Active" : "Activate Era"
    }

    @objc private func activateClicked() {
        let row = tableView.selectedRow >= 0 ? tableView.selectedRow : 0
        let eras = EraManager.shared.availableEras
        guard row < eras.count else { return }
        let era = eras[row]

        EraManager.shared.selectEra(id: era.manifest.id)
        tableView.reloadData()
        updateSelectedEraDetails()
    }

    @objc private func importClicked() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a .taskintosh-era bundle or folder"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                _ = try EraManager.shared.importEra(from: url)
                tableView.reloadData()
                updateSelectedEraDetails()
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    @objc private func reloadClicked() {
        EraManager.shared.reloadAvailableEras()
        tableView.reloadData()
        updateSelectedEraDetails()
        updateAccessibilityStatus()
    }

    @objc private func hideDockClicked() {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "defaults write com.apple.dock autohide -bool true && killall Dock"]
        try? task.run()
    }

    @objc private func restoreDockClicked() {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "defaults write com.apple.dock autohide -bool false && killall Dock"]
        try? task.run()
    }

    @objc private func a11yClicked() {
        WindowAccessibilityBridge.shared.openAccessibilitySettings()
    }
}
