import AppKit
import TaskintoshKit

public final class Win95FindDialog: NSWindowController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    public static let shared = Win95FindDialog()

    private let namedField = NSTextField()
    private let findNowButton = NSButton()
    private let newSearchButton = NSButton()
    private let resultsTableView = NSTableView()
    private let statusLabel = NSTextField()
    private var results: [StartMenuSearchResult] = []

    public init() {
        let win = NSWindow(
            contentRect: NSRect(x: 200, y: 300, width: 480, height: 380),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Find: All Files"
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 420, height: 320)
        super.init(window: win)

        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    public func showDialog() {
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        namedField.becomeFirstResponder()
    }

    private func setupUI() {
        guard let win = window else { return }
        let contentView = Win95FindContentView(frame: win.contentRect(forFrameRect: win.frame))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 1.0).cgColor
        win.contentView = contentView

        let w = contentView.bounds.width
        let h = contentView.bounds.height

        // 1. Classic Tabs Header ("Name & Location")
        let tabHeader = NSTextField(labelWithString: "Name & Location")
        tabHeader.frame = NSRect(x: 16, y: h - 34, width: 140, height: 20)
        tabHeader.font = NSFont.boldSystemFont(ofSize: 11)
        tabHeader.textColor = .black
        contentView.addSubview(tabHeader)

        // 2. Named: label & textfield
        let namedLabel = NSTextField(labelWithString: "Named:")
        namedLabel.frame = NSRect(x: 24, y: h - 68, width: 60, height: 18)
        namedLabel.font = NSFont.systemFont(ofSize: 11)
        namedLabel.textColor = .black
        contentView.addSubview(namedLabel)

        namedField.frame = NSRect(x: 90, y: h - 70, width: w - 210, height: 22)
        namedField.font = NSFont.systemFont(ofSize: 11)
        namedField.bezelStyle = .squareBezel
        namedField.isBezeled = true
        namedField.delegate = self
        contentView.addSubview(namedField)

        // 3. Look in: label & field
        let lookInLabel = NSTextField(labelWithString: "Look in:")
        lookInLabel.frame = NSRect(x: 24, y: h - 98, width: 60, height: 18)
        lookInLabel.font = NSFont.systemFont(ofSize: 11)
        lookInLabel.textColor = .black
        contentView.addSubview(lookInLabel)

        let lookInField = NSTextField(labelWithString: "Macintosh HD (Local Hard Drives)")
        lookInField.frame = NSRect(x: 90, y: h - 98, width: w - 210, height: 20)
        lookInField.font = NSFont.systemFont(ofSize: 11)
        lookInField.textColor = .darkGray
        contentView.addSubview(lookInField)

        // 4. Action Buttons (Right rail)
        findNowButton.frame = NSRect(x: w - 105, y: h - 45, width: 90, height: 24)
        findNowButton.title = "Find Now"
        findNowButton.bezelStyle = .regularSquare
        findNowButton.font = NSFont.systemFont(ofSize: 11)
        findNowButton.target = self
        findNowButton.action = #selector(findNowClicked)
        contentView.addSubview(findNowButton)

        let stopButton = NSButton(frame: NSRect(x: w - 105, y: h - 75, width: 90, height: 24))
        stopButton.title = "Stop"
        stopButton.bezelStyle = .regularSquare
        stopButton.font = NSFont.systemFont(ofSize: 11)
        stopButton.isEnabled = false
        contentView.addSubview(stopButton)

        newSearchButton.frame = NSRect(x: w - 105, y: h - 105, width: 90, height: 24)
        newSearchButton.title = "New Search"
        newSearchButton.bezelStyle = .regularSquare
        newSearchButton.font = NSFont.systemFont(ofSize: 11)
        newSearchButton.target = self
        newSearchButton.action = #selector(newSearchClicked)
        contentView.addSubview(newSearchButton)

        // 5. Results Scroll & Table View
        let scroll = NSScrollView(frame: NSRect(x: 16, y: 32, width: w - 32, height: h - 150))
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autoresizingMask = [.width, .height]
        scroll.borderType = .bezelBorder

        let colName = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        colName.title = "Name"
        colName.width = 180
        resultsTableView.addTableColumn(colName)

        let colInFolder = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("InFolder"))
        colInFolder.title = "In Folder"
        colInFolder.width = 160
        resultsTableView.addTableColumn(colInFolder)

        let colType = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Type"))
        colType.title = "Type"
        colType.width = 90
        resultsTableView.addTableColumn(colType)

        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        resultsTableView.doubleAction = #selector(tableRowDoubleClicked)
        resultsTableView.target = self
        resultsTableView.rowHeight = 20

        scroll.documentView = resultsTableView
        contentView.addSubview(scroll)

        // 6. Status bar at bottom
        statusLabel.frame = NSRect(x: 16, y: 8, width: w - 32, height: 18)
        statusLabel.font = NSFont.systemFont(ofSize: 10)
        statusLabel.textColor = .black
        statusLabel.stringValue = "0 file(s) found"
        contentView.addSubview(statusLabel)
    }

    @objc private func findNowClicked() {
        let query = namedField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        let win95Era = EraManager.shared.availableEras.first(where: { $0.manifest.id == "org.taskintosh.era.windows95" })
        results = StartMenuSearchEngine.shared.search(query: query, era: win95Era)
        resultsTableView.reloadData()
        statusLabel.stringValue = "\(results.count) file(s) found"
    }

    @objc private func newSearchClicked() {
        namedField.stringValue = ""
        results = []
        resultsTableView.reloadData()
        statusLabel.stringValue = "0 file(s) found"
        namedField.becomeFirstResponder()
    }

    @objc private func tableRowDoubleClicked() {
        let row = resultsTableView.clickedRow
        guard row >= 0 && row < results.count else { return }
        results[row].action()
    }

    public func controlTextDidEndEditing(_ obj: Notification) {
        findNowClicked()
    }

    // MARK: - NSTableViewDataSource & Delegate
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0 && row < results.count else { return nil }
        let item = results[row]

        let cell = NSTableCellView()
        let tf = NSTextField(labelWithString: "")
        tf.font = NSFont.systemFont(ofSize: 11)
        tf.textColor = .black

        if tableColumn?.identifier.rawValue == "Name" {
            let iv = NSImageView(frame: NSRect(x: 2, y: 2, width: 16, height: 16))
            iv.image = item.icon
            cell.addSubview(iv)
            tf.frame = NSRect(x: 22, y: 2, width: (tableColumn?.width ?? 180) - 26, height: 16)
            tf.stringValue = item.title
            cell.addSubview(tf)
        } else if tableColumn?.identifier.rawValue == "InFolder" {
            tf.frame = NSRect(x: 2, y: 2, width: (tableColumn?.width ?? 160) - 4, height: 16)
            tf.stringValue = item.subtitle
            cell.addSubview(tf)
        } else {
            tf.frame = NSRect(x: 2, y: 2, width: (tableColumn?.width ?? 90) - 4, height: 16)
            tf.stringValue = item.category.rawValue
            cell.addSubview(tf)
        }

        return cell
    }
}

final class Win95FindContentView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 1.0).setFill()
        bounds.fill()

        let theme = EraManager.shared.activeEra.theme
        BevelRenderer.shared.drawRaisedBevel(in: bounds, theme: theme)

        // Draw classic tab border around the upper tab
        let tabRect = NSRect(x: 12, y: bounds.height - 38, width: 130, height: 26)
        BevelRenderer.shared.drawRaisedBevel(in: tabRect, theme: theme)
    }
}
