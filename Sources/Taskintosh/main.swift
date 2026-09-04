import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

if CommandLine.arguments.contains("--validate") {
    DispatchQueue.main.async {
        Task {
            await runPackagedAppValidation()
        }
    }
} else if let snapshotIdx = CommandLine.arguments.firstIndex(where: { $0 == "--snapshot" || $0 == "--snapshots" }),
          snapshotIdx + 1 < CommandLine.arguments.count {
    let outputDir = CommandLine.arguments[snapshotIdx + 1]
    DispatchQueue.main.async {
        exportEraSnapshots(outputDirPath: outputDir)
    }
}

app.run()
