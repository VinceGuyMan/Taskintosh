import TaskintoshKit
import AppKit


public final class ShutDownDialog: NSWindow {
    private var selectedOption: Int = 0 // 0: Shutdown, 1: Restart, 2: Log Off

    public init() {
        let rect = NSRect(x: 0, y: 0, width: 380, height: 210)
        super.init(
            contentRect: rect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = "Shut Down Taskintosh"
        self.isReleasedWhenClosed = false
        self.center()

        let era = EraManager.shared.activeEra
        let contentView = NSView(frame: rect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = era.theme.surfaceColor.cgColor
        self.contentView = contentView

        // Icon
        let iconView = NSImageView(frame: NSRect(x: 16, y: 150, width: 36, height: 36))
        iconView.image = ProceduralIcons.shared.shutDownIcon(size: 36)
        contentView.addSubview(iconView)

        // Question
        let question = NSTextField(labelWithString: "What do you want the computer to do?")
        question.frame = NSRect(x: 64, y: 160, width: 290, height: 20)
        question.font = era.theme.boldFont(size: 11)
        question.textColor = era.theme.textColor
        contentView.addSubview(question)

        // Radio buttons
        let radio1 = NSButton(radioButtonWithTitle: "Shut down the computer", target: self, action: #selector(radioChanged(_:)))
        radio1.tag = 0
        radio1.state = .on
        radio1.frame = NSRect(x: 64, y: 125, width: 250, height: 18)
        contentView.addSubview(radio1)

        let radio2 = NSButton(radioButtonWithTitle: "Restart the computer", target: self, action: #selector(radioChanged(_:)))
        radio2.tag = 1
        radio2.frame = NSRect(x: 64, y: 100, width: 250, height: 18)
        contentView.addSubview(radio2)

        let radio3 = NSButton(radioButtonWithTitle: "Log off user", target: self, action: #selector(radioChanged(_:)))
        radio3.tag = 2
        radio3.frame = NSRect(x: 64, y: 75, width: 250, height: 18)
        contentView.addSubview(radio3)

        // Buttons
        let yesButton = NSButton(frame: NSRect(x: 120, y: 16, width: 75, height: 24))
        yesButton.title = "Yes"
        yesButton.bezelStyle = .rounded
        yesButton.target = self
        yesButton.action = #selector(yesClicked)
        yesButton.keyEquivalent = "\r"
        contentView.addSubview(yesButton)

        let noButton = NSButton(frame: NSRect(x: 205, y: 16, width: 75, height: 24))
        noButton.title = "No"
        noButton.bezelStyle = .rounded
        noButton.target = self
        noButton.action = #selector(noClicked)
        noButton.keyEquivalent = "\u{1b}"
        contentView.addSubview(noButton)

        let helpButton = NSButton(frame: NSRect(x: 290, y: 16, width: 75, height: 24))
        helpButton.title = "Help"
        helpButton.bezelStyle = .rounded
        helpButton.target = self
        helpButton.action = #selector(helpClicked)
        contentView.addSubview(helpButton)
    }

    @objc private func radioChanged(_ sender: NSButton) {
        self.selectedOption = sender.tag
    }

    @objc private func yesClicked() {
        self.close()
        let script: String
        switch selectedOption {
        case 0:
            script = "tell application \"System Events\" to shut down"
        case 1:
            script = "tell application \"System Events\" to restart"
        case 2:
            script = "tell application \"System Events\" to log out"
        default:
            return
        }

        let alert = NSAlert()
        alert.messageText = "Confirm Action"
        alert.informativeText = "Are you sure you want to proceed with this system power action?"
        alert.addButton(withTitle: "Proceed")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    @objc private func noClicked() {
        self.close()
    }

    @objc private func helpClicked() {
        let alert = NSAlert()
        alert.messageText = "Taskintosh Help"
        alert.informativeText = "Shut down turns off your Mac. Restart reboots your Mac. Log off ends the current macOS user session."
        alert.runModal()
    }
}
