import TaskintoshKit
import AppKit


private final class TopUpdateIconButton: NSButton {
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

public final class EraManagerWindow: NSWindow, NSTableViewDataSource, NSTableViewDelegate {
    private let tableView = NSTableView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let periodLabel = NSTextField(labelWithString: "")
    private let versionLabel = NSTextField(labelWithString: "")
    private let authorLabel = NSTextField(labelWithString: "")
    private let descLabel = NSTextField(labelWithString: "")
    private let activateButton = NSButton()
    private let accessibilityStatusLabel = NSTextField(labelWithString: "")
    private let soundToggleButton = NSButton()
    private let previewSoundButton = NSButton()

    // Top update icon & status
    private let updateIconButton = TopUpdateIconButton()
    private let updateStatusLabel = NSTextField(labelWithString: "")
    private let updateSpinner = NSProgressIndicator()

    public init() {
        let rect = NSRect(x: 0, y: 0, width: 570, height: 470)
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
        header.frame = NSRect(x: 20, y: 426, width: 300, height: 24)
        header.font = NSFont.boldSystemFont(ofSize: 15)
        contentView.addSubview(header)

        // Subtitle
        let subheader = NSTextField(labelWithString: "“Desktop history, openly rebuilt for Mac.”")
        subheader.frame = NSRect(x: 20, y: 406, width: 300, height: 18)
        subheader.font = NSFont.systemFont(ofSize: 11)
        subheader.textColor = .secondaryLabelColor
        contentView.addSubview(subheader)

        // Top Icon for Updates
        let appIcon = loadAppIcon(size: 44)
        updateIconButton.frame = NSRect(x: 498, y: 400, width: 52, height: 52)
        updateIconButton.image = appIcon
        updateIconButton.imagePosition = .imageOnly
        updateIconButton.imageScaling = .scaleProportionallyUpOrDown
        updateIconButton.isBordered = false
        updateIconButton.wantsLayer = true
        updateIconButton.layer?.cornerRadius = 10
        updateIconButton.layer?.masksToBounds = true
        updateIconButton.layer?.borderWidth = 1
        updateIconButton.layer?.borderColor = NSColor.separatorColor.cgColor
        updateIconButton.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        updateIconButton.toolTip = "Click to update Taskintosh & relaunch"
        updateIconButton.target = self
        updateIconButton.action = #selector(topIconUpdateClicked)
        updateIconButton.setAccessibilityIdentifier("TopUpdateIconButton")
        contentView.addSubview(updateIconButton)

        // Update status label & spinner
        updateStatusLabel.frame = NSRect(x: 270, y: 426, width: 220, height: 18)
        updateStatusLabel.alignment = .right
        updateStatusLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        updateStatusLabel.textColor = .secondaryLabelColor
        updateStatusLabel.stringValue = "v\(AppUpdateService.shared.currentAppVersion()) • Click icon to update"
        updateStatusLabel.setAccessibilityIdentifier("TopUpdateStatusLabel")
        contentView.addSubview(updateStatusLabel)

        updateSpinner.frame = NSRect(x: 474, y: 406, width: 16, height: 16)
        updateSpinner.style = .spinning
        updateSpinner.controlSize = .small
        updateSpinner.isDisplayedWhenStopped = false
        contentView.addSubview(updateSpinner)

        // Table scroll view on left
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 154, width: 224, height: 240))
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
        let detailBox = NSBox(frame: NSRect(x: 254, y: 154, width: 296, height: 240))
        detailBox.title = "Era Information"
        detailBox.contentView?.addSubview(nameLabel)
        detailBox.contentView?.addSubview(periodLabel)
        detailBox.contentView?.addSubview(versionLabel)
        detailBox.contentView?.addSubview(authorLabel)
        detailBox.contentView?.addSubview(descLabel)
        detailBox.contentView?.addSubview(activateButton)
        detailBox.contentView?.addSubview(previewSoundButton)

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

        activateButton.frame = NSRect(x: 12, y: 10, width: 115, height: 26)
        activateButton.title = "Activate Era"
        activateButton.bezelStyle = .rounded
        activateButton.target = self
        activateButton.action = #selector(activateClicked)

        previewSoundButton.frame = NSRect(x: 135, y: 10, width: 125, height: 26)
        previewSoundButton.title = "▶ Preview Sound"
        previewSoundButton.bezelStyle = .rounded
        previewSoundButton.target = self
        previewSoundButton.action = #selector(previewSoundClicked)
        previewSoundButton.setAccessibilityIdentifier("PreviewEraSoundButton")

        contentView.addSubview(detailBox)

        // Buttons below table
        let importButton = NSButton(frame: NSRect(x: 20, y: 114, width: 80, height: 26))
        importButton.title = "Import..."
        importButton.bezelStyle = .rounded
        importButton.target = self
        importButton.action = #selector(importClicked)
        contentView.addSubview(importButton)

        let reloadButton = NSButton(frame: NSRect(x: 104, y: 114, width: 76, height: 26))
        reloadButton.title = "Reload"
        reloadButton.bezelStyle = .rounded
        reloadButton.target = self
        reloadButton.action = #selector(reloadClicked)
        contentView.addSubview(reloadButton)

        soundToggleButton.frame = NSRect(x: 184, y: 114, width: 88, height: 26)
        soundToggleButton.bezelStyle = .rounded
        updateSoundButtonTitle()
        soundToggleButton.target = self
        soundToggleButton.action = #selector(soundToggleClicked)
        soundToggleButton.setAccessibilityIdentifier("EraSoundToggleButton")
        contentView.addSubview(soundToggleButton)

        // Generation Transition Effect Selector
        let transitionLabel = NSTextField(labelWithString: "Transition:")
        transitionLabel.frame = NSRect(x: 280, y: 117, width: 68, height: 18)
        transitionLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        transitionLabel.textColor = .secondaryLabelColor
        contentView.addSubview(transitionLabel)

        let transitionPopup = NSPopUpButton(frame: NSRect(x: 350, y: 112, width: 200, height: 26), pullsDown: false)
        for effect in TaskbarTransitionEffect.allCases {
            transitionPopup.addItem(withTitle: effect.displayName)
            transitionPopup.lastItem?.representedObject = effect.rawValue
        }
        transitionPopup.addItem(withTitle: "Random (Cycle Each Switch)")
        transitionPopup.lastItem?.representedObject = "random"

        if TaskbarTransitionEffect.isCycleMode {
            transitionPopup.selectItem(withTitle: "Random (Cycle Each Switch)")
        } else {
            transitionPopup.selectItem(withTitle: TaskbarTransitionEffect.preferredEffect.displayName)
        }

        transitionPopup.target = self
        transitionPopup.action = #selector(transitionEffectChanged(_:))
        transitionPopup.setAccessibilityIdentifier("TransitionEffectPopup")
        contentView.addSubview(transitionPopup)

        // Bottom section: System Integrations & Helpers
        let helperBox = NSBox(frame: NSRect(x: 20, y: 12, width: 530, height: 90))
        helperBox.title = "macOS Integration & Dock Helper"

        let hideDockBtn = NSButton(frame: NSRect(x: 12, y: 12, width: 156, height: 26))
        hideDockBtn.title = "Auto-Hide macOS Dock"
        hideDockBtn.bezelStyle = .rounded
        hideDockBtn.target = self
        hideDockBtn.action = #selector(hideDockClicked)
        helperBox.contentView?.addSubview(hideDockBtn)

        let restoreDockBtn = NSButton(frame: NSRect(x: 174, y: 12, width: 156, height: 26))
        restoreDockBtn.title = "Restore macOS Dock"
        restoreDockBtn.bezelStyle = .rounded
        restoreDockBtn.target = self
        restoreDockBtn.action = #selector(restoreDockClicked)
        helperBox.contentView?.addSubview(restoreDockBtn)

        let a11yBtn = NSButton(frame: NSRect(x: 336, y: 12, width: 166, height: 26))
        a11yBtn.title = "Accessibility Settings..."
        a11yBtn.bezelStyle = .rounded
        a11yBtn.target = self
        a11yBtn.action = #selector(a11yClicked)
        helperBox.contentView?.addSubview(a11yBtn)

        accessibilityStatusLabel.frame = NSRect(x: 14, y: 46, width: 502, height: 16)
        accessibilityStatusLabel.font = NSFont.systemFont(ofSize: 10)
        helperBox.contentView?.addSubview(accessibilityStatusLabel)

        contentView.addSubview(helperBox)

        updateAccessibilityStatus()
        updateSelectedEraDetails()
    }

    public func updateAccessibilityStatus() {
        let trusted = WindowAccessibilityBridge.shared.isAccessibilityTrusted
        if trusted {
            accessibilityStatusLabel.stringValue = "Accessibility: Enabled (automatic taskbar window layout active)"
            accessibilityStatusLabel.textColor = .systemGreen
        } else {
            accessibilityStatusLabel.stringValue = "Accessibility: Enable for automatic window layout around the taskbar"
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
        WindowAccessibilityBridge.shared.promptForAccessibility()
        WindowAccessibilityBridge.shared.openAccessibilitySettings()
    }

    @objc private func transitionEffectChanged(_ sender: NSPopUpButton) {
        guard let raw = sender.selectedItem?.representedObject as? String else { return }
        if raw == "random" {
            TaskbarTransitionEffect.isCycleMode = true
        } else if let effect = TaskbarTransitionEffect(rawValue: raw) {
            TaskbarTransitionEffect.isCycleMode = false
            TaskbarTransitionEffect.preferredEffect = effect
        }
    }

    @objc private func previewSoundClicked() {
        let row = tableView.selectedRow >= 0 ? tableView.selectedRow : 0
        let eras = EraManager.shared.availableEras
        guard row < eras.count else { return }
        let era = eras[row]
        EraSoundManager.shared.playStartupSound(for: era, ignoreMute: true)
    }

    @objc private func soundToggleClicked() {
        EraSoundManager.shared.isSoundEnabled.toggle()
        updateSoundButtonTitle()
        if EraSoundManager.shared.isSoundEnabled {
            let row = tableView.selectedRow >= 0 ? tableView.selectedRow : 0
            let eras = EraManager.shared.availableEras
            if row < eras.count {
                EraSoundManager.shared.playStartupSound(for: eras[row])
            }
        }
    }

    private func updateSoundButtonTitle() {
        let enabled = EraSoundManager.shared.isSoundEnabled
        soundToggleButton.title = enabled ? "🔊 Sound" : "🔇 Muted"
        soundToggleButton.toolTip = enabled ? "Startup sound plays on era change (click to mute)" : "Startup sound is muted (click to enable)"
    }

    private func loadAppIcon(size: CGFloat) -> NSImage {
        if let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") ?? Bundle.main.url(forResource: "taskintosh-icon-128", withExtension: "png"),
           let img = NSImage(contentsOf: iconUrl) {
            let resized = NSImage(size: NSSize(width: size, height: size))
            resized.lockFocus()
            img.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1.0)
            resized.unlockFocus()
            return resized
        }
        return ProceduralIcons.shared.taskintoshIcon(size: size)
    }

    @objc public func topIconUpdateClicked() {
        startUpdateFlow(forceReinstall: false)
    }

    public func startUpdateFlow(forceReinstall: Bool = false) {
        updateStatusLabel.stringValue = "Checking for updates..."
        updateStatusLabel.textColor = .labelColor
        updateSpinner.startAnimation(nil)
        updateIconButton.isEnabled = false

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let result = await AppUpdateService.shared.checkAndApplyUpdate(forceReinstall: forceReinstall)
            self.updateSpinner.stopAnimation(nil)
            self.updateIconButton.isEnabled = true

            switch result {
            case .updatedAndRelaunching:
                self.updateStatusLabel.stringValue = "Restarting Taskintosh..."
                self.updateStatusLabel.textColor = .systemGreen

            case .fallbackToGitHub(let url, let reason):
                self.updateStatusLabel.stringValue = "Opened GitHub"
                self.updateStatusLabel.textColor = .systemOrange
                let alert = NSAlert()
                alert.messageText = "Update via GitHub"
                alert.informativeText = "\(reason)\n\nTaskintosh has opened the GitHub releases page in your browser."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Re-open GitHub")
                if alert.runModal() == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(url)
                }

            case .alreadyUpToDate(let version, let hasPackageAsset):
                self.updateStatusLabel.stringValue = "v\(version) (Up to date)"
                self.updateStatusLabel.textColor = .secondaryLabelColor
                let alert = NSAlert()
                alert.messageText = "Taskintosh is Up to Date"
                alert.informativeText = "You are currently running version \(version)."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Visit GitHub")
                if hasPackageAsset {
                    alert.addButton(withTitle: "Reinstall")
                }
                let response = alert.runModal()
                if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(AppUpdateConfig.standard.gitHubReleasesWebURL)
                } else if response == .alertThirdButtonReturn {
                    self.startUpdateFlow(forceReinstall: true)
                }

            case .failed(let message):
                self.updateStatusLabel.stringValue = "Check failed"
                self.updateStatusLabel.textColor = .systemRed
                let alert = NSAlert()
                alert.messageText = "Update Check Failed"
                alert.informativeText = "\(message)\n\nOpening the GitHub releases page..."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open GitHub")
                alert.addButton(withTitle: "Cancel")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(AppUpdateConfig.standard.gitHubReleasesWebURL)
                }
            }
        }
    }
}

