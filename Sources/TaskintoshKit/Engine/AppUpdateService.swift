import Foundation
import AppKit

/// Configuration for GitHub repository update checks and downloads.
public struct AppUpdateConfig: Equatable, Sendable {
    public var owner: String
    public var repo: String
    public var releasesURL: URL
    public var gitHubReleasesWebURL: URL
    public var fallbackWebURL: URL

    public static let standard = AppUpdateConfig(
        owner: "VinceGuyMan",
        repo: "Taskintosh",
        releasesURL: URL(string: "https://api.github.com/repos/VinceGuyMan/Taskintosh/releases")!,
        gitHubReleasesWebURL: URL(string: "https://github.com/VinceGuyMan/Taskintosh/releases")!,
        fallbackWebURL: URL(string: "https://github.com/VinceGuyMan/Taskintosh")!
    )

    public init(
        owner: String,
        repo: String,
        releasesURL: URL,
        gitHubReleasesWebURL: URL,
        fallbackWebURL: URL
    ) {
        self.owner = owner
        self.repo = repo
        self.releasesURL = releasesURL
        self.gitHubReleasesWebURL = gitHubReleasesWebURL
        self.fallbackWebURL = fallbackWebURL
    }
}

/// Parsed semantic version for comparison.
public struct SemanticVersion: Comparable, Equatable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?

    public init(string: String) {
        var clean = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().hasPrefix("v") {
            clean = String(clean.dropFirst())
        }
        let parts = clean.split(separator: "-", maxSplits: 1)
        let core = parts.first ?? ""
        self.prerelease = parts.count > 1 ? String(parts[1]) : nil

        let nums = core.split(separator: ".").compactMap { Int($0) }
        self.major = nums.count > 0 ? nums[0] : 0
        self.minor = nums.count > 1 ? nums[1] : 0
        self.patch = nums.count > 2 ? nums[2] : 0
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        if lhs.prerelease == nil && rhs.prerelease != nil { return false }
        if lhs.prerelease != nil && rhs.prerelease == nil { return true }
        if let lp = lhs.prerelease, let rp = rhs.prerelease { return lp < rp }
        return false
    }
}

/// GitHub Release model matching GitHub REST API v3.
public struct GitHubRelease: Codable, Equatable, Sendable {
    public let id: Int
    public let tagName: String
    public let name: String?
    public let htmlUrl: String
    public let body: String?
    public let draft: Bool
    public let prerelease: Bool
    public let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case body
        case draft
        case prerelease
        case assets
    }

    public init(
        id: Int,
        tagName: String,
        name: String?,
        htmlUrl: String,
        body: String?,
        draft: Bool,
        prerelease: Bool,
        assets: [GitHubReleaseAsset]
    ) {
        self.id = id
        self.tagName = tagName
        self.name = name
        self.htmlUrl = htmlUrl
        self.body = body
        self.draft = draft
        self.prerelease = prerelease
        self.assets = assets
    }

    /// Finds the best downloadable package asset (.zip)
    public var packageAsset: GitHubReleaseAsset? {
        if let universal = assets.first(where: {
            let lower = $0.name.lowercased()
            return lower.hasSuffix(".zip") && lower.contains("taskintosh")
        }) {
            return universal
        }
        return assets.first(where: { $0.name.lowercased().hasSuffix(".zip") })
    }
}

/// GitHub Release Asset model matching GitHub REST API v3.
public struct GitHubReleaseAsset: Codable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let contentType: String?
    public let size: Int
    public let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contentType = "content_type"
        case size
        case browserDownloadUrl = "browser_download_url"
    }

    public init(
        id: Int,
        name: String,
        contentType: String?,
        size: Int,
        browserDownloadUrl: String
    ) {
        self.id = id
        self.name = name
        self.contentType = contentType
        self.size = size
        self.browserDownloadUrl = browserDownloadUrl
    }
}

/// Outcome of checking and applying an update.
public enum UpdateResult: Equatable, Sendable {
    case updatedAndRelaunching(targetURL: URL)
    case fallbackToGitHub(url: URL, reason: String)
    case alreadyUpToDate(version: String, hasPackageAsset: Bool)
    case failed(message: String)
}

/// Specific errors that can occur during the update process.
public enum UpdateError: LocalizedError, Equatable {
    case serverError(statusCode: Int)
    case extractionFailed(code: Int32)
    case appBundleNotFound
    case destinationNotWritable(path: String)
    case invalidDownloadURL

    public var errorDescription: String? {
        switch self {
        case .serverError(let code):
            return "Server responded with status code \(code)."
        case .extractionFailed(let code):
            return "Extraction failed with exit code \(code)."
        case .appBundleNotFound:
            return "Taskintosh.app could not be found in the downloaded package."
        case .destinationNotWritable(let path):
            return "Destination path is not writable: \(path)."
        case .invalidDownloadURL:
            return "Download URL is invalid."
        }
    }
}

/// Core updater service for pulling Taskintosh packages, downloading to place, and relaunching.
@MainActor
public final class AppUpdateService: ObservableObject {
    public static let shared = AppUpdateService()

    public var urlSession: URLSession = .shared
    public var terminateAppOnRelaunch: Bool = true

    public init() {}

    /// Current version of Taskintosh.
    public func currentAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        return "1.2.0"
    }

    /// Identifies where the app bundle is located on disk ("its spot").
    public func determineAppSpot() -> URL {
        let mainBundle = Bundle.main.bundleURL
        if mainBundle.pathExtension == "app" {
            return mainBundle
        }

        // When running from SPM / CLI / dev test, check standard locations
        let standardApp = URL(fileURLWithPath: "/Applications/Taskintosh.app")
        if FileManager.default.fileExists(atPath: standardApp.path) {
            return standardApp
        }

        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let buildApp = currentDir.appendingPathComponent("build/Taskintosh.app")
        if FileManager.default.fileExists(atPath: buildApp.path) {
            return buildApp
        }

        return standardApp
    }

    /// Fetches releases list from GitHub.
    public func fetchReleases(config: AppUpdateConfig = .standard) async throws -> [GitHubRelease] {
        var request = URLRequest(url: config.releasesURL)
        request.httpMethod = "GET"
        request.setValue("Taskintosh-App", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw UpdateError.serverError(statusCode: code)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([GitHubRelease].self, from: data)
    }

    /// Extracts a zip package to destinationDirectory using macOS ditto and locates Taskintosh.app.
    public func extractPackage(zipURL: URL, destinationDirectory: URL) throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", zipURL.path, destinationDirectory.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.extractionFailed(code: process.terminationStatus)
        }

        guard let appURL = findAppBundle(in: destinationDirectory) else {
            throw UpdateError.appBundleNotFound
        }

        return appURL
    }

    /// Recursively looks for Taskintosh.app inside an unpacked directory.
    public func findAppBundle(in directory: URL) -> URL? {
        let fileManager = FileManager.default
        let directApp = directory.appendingPathComponent("Taskintosh.app")
        if fileManager.fileExists(atPath: directApp.path) {
            return directApp
        }

        if let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator {
                if url.pathExtension == "app" {
                    return url
                }
            }
        }
        return nil
    }

    /// Builds the detached relaunch shell script that swaps the new app into its spot and relaunches it.
    public func buildRelaunchScript(
        currentPID: Int32,
        sourceAppURL: URL,
        targetAppURL: URL,
        stagingDirURL: URL,
        fallbackURL: URL
    ) -> String {
        return """
        #!/bin/sh
        OLD_PID=\(currentPID)
        SOURCE_APP="\(sourceAppURL.path)"
        TARGET_APP="\(targetAppURL.path)"
        STAGING_DIR="\(stagingDirURL.path)"
        FALLBACK_URL="\(fallbackURL.absoluteString)"

        # 1. Wait for current Taskintosh process to exit
        while kill -0 "$OLD_PID" 2>/dev/null; do
            sleep 0.2
        done

        # 2. Verify source app exists
        if [ ! -d "$SOURCE_APP" ]; then
            open "$FALLBACK_URL"
            rm -rf "$STAGING_DIR"
            exit 1
        fi

        # 3. Replace target app in its spot
        rm -rf "$TARGET_APP"
        cp -R "$SOURCE_APP" "$TARGET_APP"
        COPY_STATUS=$?

        if [ $COPY_STATUS -ne 0 ] || [ ! -d "$TARGET_APP" ]; then
            open "$FALLBACK_URL"
            rm -rf "$STAGING_DIR"
            exit 1
        fi

        # 4. Clear quarantine flags
        xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true

        # 5. Relaunch the new application in its spot
        open "$TARGET_APP"

        # 6. Cleanup staging directory
        rm -rf "$STAGING_DIR"
        exit 0
        """
    }

    /// Downloads the package from downloadURL, extracts to a staging area, replaces app at targetAppURL, and relaunches.
    public func downloadAndInstall(
        from downloadURL: URL,
        targetAppURL: URL,
        fallbackURL: URL
    ) async throws {
        var request = URLRequest(url: downloadURL)
        request.setValue("Taskintosh-App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 60.0

        let (tempLocalURL, _) = try await urlSession.download(for: request)

        let stagingDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaskintoshUpdate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)

        let zipPath = stagingDir.appendingPathComponent("update.zip")
        try FileManager.default.moveItem(at: tempLocalURL, to: zipPath)

        let extractedAppURL = try extractPackage(zipURL: zipPath, destinationDirectory: stagingDir)

        // Check if destination directory is writable
        let targetParent = targetAppURL.deletingLastPathComponent()
        if !FileManager.default.isWritableFile(atPath: targetParent.path) &&
           !FileManager.default.isWritableFile(atPath: targetAppURL.path) {
            throw UpdateError.destinationNotWritable(path: targetAppURL.path)
        }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let scriptContent = buildRelaunchScript(
            currentPID: currentPID,
            sourceAppURL: extractedAppURL,
            targetAppURL: targetAppURL,
            stagingDirURL: stagingDir,
            fallbackURL: fallbackURL
        )

        let scriptURL = stagingDir.appendingPathComponent("relaunch.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptURL.path]
        try process.run()

        if terminateAppOnRelaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSApplication.shared.terminate(nil)
                exit(0)
            }
        }
    }

    /// Initiates checking and applying an update. If no package or error, falls back to the GitHub releases page.
    public func checkAndApplyUpdate(
        config: AppUpdateConfig = .standard,
        forceReinstall: Bool = false,
        openBrowserOnFallback: Bool = true
    ) async -> UpdateResult {
        let currentVersion = currentAppVersion()
        let releases: [GitHubRelease]
        do {
            releases = try await fetchReleases(config: config)
        } catch {
            let fallbackURL = config.gitHubReleasesWebURL
            if openBrowserOnFallback {
                NSWorkspace.shared.open(fallbackURL)
            }
            return .fallbackToGitHub(url: fallbackURL, reason: "Could not fetch updates from GitHub: \(error.localizedDescription)")
        }

        guard let latestRelease = releases.first(where: { !$0.draft }) else {
            let fallbackURL = config.gitHubReleasesWebURL
            if openBrowserOnFallback {
                NSWorkspace.shared.open(fallbackURL)
            }
            return .fallbackToGitHub(url: fallbackURL, reason: "No published releases found.")
        }

        let releaseURL = URL(string: latestRelease.htmlUrl) ?? config.gitHubReleasesWebURL
        let remoteVersion = SemanticVersion(string: latestRelease.tagName)
        let localVersion = SemanticVersion(string: currentVersion)

        guard let packageAsset = latestRelease.packageAsset else {
            // Fallback lead to GitHub page when package is not attached
            if openBrowserOnFallback {
                NSWorkspace.shared.open(releaseURL)
            }
            return .fallbackToGitHub(url: releaseURL, reason: "Release \(latestRelease.tagName) does not have a downloadable package attached.")
        }

        if !forceReinstall && remoteVersion <= localVersion {
            return .alreadyUpToDate(version: currentVersion, hasPackageAsset: true)
        }

        guard let downloadURL = URL(string: packageAsset.browserDownloadUrl) else {
            if openBrowserOnFallback {
                NSWorkspace.shared.open(releaseURL)
            }
            return .fallbackToGitHub(url: releaseURL, reason: "Invalid package download URL.")
        }

        do {
            let targetSpot = determineAppSpot()
            try await downloadAndInstall(
                from: downloadURL,
                targetAppURL: targetSpot,
                fallbackURL: releaseURL
            )
            return .updatedAndRelaunching(targetURL: targetSpot)
        } catch {
            if openBrowserOnFallback {
                NSWorkspace.shared.open(releaseURL)
            }
            return .fallbackToGitHub(url: releaseURL, reason: "Update installation failed: \(error.localizedDescription)")
        }
    }
}
