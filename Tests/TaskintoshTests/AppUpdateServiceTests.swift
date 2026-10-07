import XCTest
import Foundation
@testable import TaskintoshKit

final class AppUpdateServiceTests: XCTestCase {

    // MARK: - 1. Semantic Versioning Tests
    func testSemanticVersionParsingAndComparison() {
        let v100 = SemanticVersion(string: "1.0.0")
        let v110 = SemanticVersion(string: "1.1.0")
        let v110withV = SemanticVersion(string: "v1.1.0")
        let v111 = SemanticVersion(string: "1.1.1")
        let v120 = SemanticVersion(string: "v1.2.0")
        let v200 = SemanticVersion(string: "2.0.0")
        let vBeta = SemanticVersion(string: "1.1.0-beta")

        XCTAssertEqual(v110, v110withV)
        XCTAssertTrue(v100 < v110)
        XCTAssertTrue(v110 < v111)
        XCTAssertTrue(v111 < v120)
        XCTAssertTrue(v120 < v200)
        XCTAssertTrue(vBeta < v110)
        XCTAssertFalse(v110 < v100)
        XCTAssertFalse(v110 < v110)
    }

    // MARK: - 2. GitHub Release Decoding & Package Asset Resolution
    func testReleaseDecodingWithPackageAsset() throws {
        let json = """
        {
            "id": 101,
            "tag_name": "v1.0.0",
            "name": "Taskintosh 1.0.0",
            "html_url": "https://github.com/VinceGuyMan/Taskintosh/releases/tag/v1.0.0",
            "body": "First public release",
            "draft": false,
            "prerelease": false,
            "assets": [
                {
                    "id": 201,
                    "name": "Taskintosh-1.0.0-macOS-universal.zip",
                    "content_type": "application/zip",
                    "size": 2684846,
                    "browser_download_url": "https://github.com/VinceGuyMan/Taskintosh/releases/download/v1.0.0/Taskintosh-1.0.0-macOS-universal.zip"
                }
            ]
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)
        XCTAssertEqual(release.tagName, "v1.0.0")
        XCTAssertEqual(release.assets.count, 1)

        let asset = release.packageAsset
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.name, "Taskintosh-1.0.0-macOS-universal.zip")
        XCTAssertEqual(asset?.browserDownloadUrl, "https://github.com/VinceGuyMan/Taskintosh/releases/download/v1.0.0/Taskintosh-1.0.0-macOS-universal.zip")
    }

    func testReleaseDecodingWithoutPackageAsset() throws {
        let json = """
        {
            "id": 102,
            "tag_name": "v1.1.0",
            "name": "Taskintosh 1.1.0",
            "html_url": "https://github.com/VinceGuyMan/Taskintosh/releases/tag/v1.1.0",
            "body": "Release notes without direct zip asset",
            "draft": false,
            "prerelease": false,
            "assets": []
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)
        XCTAssertEqual(release.tagName, "v1.1.0")
        XCTAssertEqual(release.assets.count, 0)
        XCTAssertNil(release.packageAsset)
    }

    // MARK: - 3. Relaunch Script Construction
    @MainActor
    func testRelaunchScriptConstruction() {
        let service = AppUpdateService()
        let pid: Int32 = 4242
        let sourceApp = URL(fileURLWithPath: "/tmp/staging/Taskintosh.app")
        let targetApp = URL(fileURLWithPath: "/Applications/Taskintosh.app")
        let stagingDir = URL(fileURLWithPath: "/tmp/staging")
        let fallbackURL = URL(string: "https://github.com/VinceGuyMan/Taskintosh/releases")!

        let script = service.buildRelaunchScript(
            currentPID: pid,
            sourceAppURL: sourceApp,
            targetAppURL: targetApp,
            stagingDirURL: stagingDir,
            fallbackURL: fallbackURL
        )

        XCTAssertTrue(script.contains("OLD_PID=4242"))
        XCTAssertTrue(script.contains("while kill -0 \"$OLD_PID\""))
        XCTAssertTrue(script.contains("rm -rf \"$TARGET_APP\""))
        XCTAssertTrue(script.contains("cp -R \"$SOURCE_APP\" \"$TARGET_APP\""))
        XCTAssertTrue(script.contains("xattr -dr com.apple.quarantine \"$TARGET_APP\""))
        XCTAssertTrue(script.contains("open \"$TARGET_APP\""))
        XCTAssertTrue(script.contains("open \"$FALLBACK_URL\""))
    }

    // MARK: - 4. Determining App Spot
    @MainActor
    func testDetermineAppSpotReturnsAppURL() {
        let service = AppUpdateService()
        let spot = service.determineAppSpot()
        XCTAssertTrue(spot.path.hasSuffix(".app"), "Spot should resolve to an .app path: \(spot.path)")
    }

    // MARK: - 5. App Bundle Discovery in Directory
    @MainActor
    func testFindAppBundleDirectAndNested() throws {
        let service = AppUpdateService()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TestBundleDiscovery-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Test direct
        let directApp = tempDir.appendingPathComponent("Taskintosh.app")
        try FileManager.default.createDirectory(at: directApp, withIntermediateDirectories: true)
        let foundDirect = service.findAppBundle(in: tempDir)
        XCTAssertEqual(foundDirect?.resolvingSymlinksInPath().path, directApp.resolvingSymlinksInPath().path)

        // Remove direct and test nested
        try FileManager.default.removeItem(at: directApp)
        let nestedSubdir = tempDir.appendingPathComponent("ExtractedFolder")
        let nestedApp = nestedSubdir.appendingPathComponent("Taskintosh.app")
        try FileManager.default.createDirectory(at: nestedApp, withIntermediateDirectories: true)

        let foundNested = service.findAppBundle(in: tempDir)
        XCTAssertEqual(foundNested?.resolvingSymlinksInPath().path, nestedApp.resolvingSymlinksInPath().path)
    }

    // MARK: - 6. Mock URLProtocol for Update Flow Testing
    final class MockURLProtocol: URLProtocol {
        static var mockResponseData: Data?
        static var mockStatusCode: Int = 200

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: Self.mockStatusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = Self.mockResponseData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    @MainActor
    func testFallbackToGitHubWhenReleaseHasNoPackageAsset() async throws {
        let service = AppUpdateService()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        service.urlSession = URLSession(configuration: config)

        let mockJSON = """
        [
            {
                "id": 999,
                "tag_name": "v9.9.9",
                "name": "Taskintosh 9.9.9",
                "html_url": "https://github.com/VinceGuyMan/Taskintosh/releases/tag/v9.9.9",
                "body": "No asset in this release",
                "draft": false,
                "prerelease": false,
                "assets": []
            }
        ]
        """.data(using: .utf8)!

        MockURLProtocol.mockResponseData = mockJSON
        MockURLProtocol.mockStatusCode = 200

        let result = await service.checkAndApplyUpdate(
            config: .standard,
            forceReinstall: false,
            openBrowserOnFallback: false
        )

        switch result {
        case .fallbackToGitHub(let url, let reason):
            XCTAssertEqual(url.absoluteString, "https://github.com/VinceGuyMan/Taskintosh/releases/tag/v9.9.9")
            XCTAssertTrue(reason.contains("does not have a downloadable package attached"))
        default:
            XCTFail("Expected fallbackToGitHub, got \(result)")
        }
    }

    @MainActor
    func testFallbackToGitHubWhenNetworkFails() async throws {
        let service = AppUpdateService()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        service.urlSession = URLSession(configuration: config)

        MockURLProtocol.mockResponseData = "Internal Server Error".data(using: .utf8)
        MockURLProtocol.mockStatusCode = 500

        let result = await service.checkAndApplyUpdate(
            config: .standard,
            forceReinstall: false,
            openBrowserOnFallback: false
        )

        switch result {
        case .fallbackToGitHub(let url, let reason):
            XCTAssertEqual(url, AppUpdateConfig.standard.gitHubReleasesWebURL)
            XCTAssertTrue(reason.contains("Could not fetch updates"))
        default:
            XCTFail("Expected fallbackToGitHub on server error, got \(result)")
        }
    }
}
