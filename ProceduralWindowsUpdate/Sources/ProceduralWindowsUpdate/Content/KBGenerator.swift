import Foundation

/// Procedural generator for authentic-looking KB identifiers and update titles.
public struct KBGenerator {

    public static func generateUpdate(
        era: WindowsEra,
        index: Int,
        total: Int,
        rng: inout SplitMix64,
        forceVibes: Bool = false
    ) -> FakeUpdateItem {
        let isSpecialRollup = forceVibes || (index == total && rng.chance(0.25))

        let kbNum: Int
        switch era {
        case .win95, .win98, .winME:
            kbNum = rng.nextInt(in: 140000...299999)
        case .winXP:
            kbNum = rng.nextInt(in: 800000...959999)
        case .winVista, .win7:
            kbNum = rng.nextInt(in: 940000...2999999)
        case .win8, .win8_1:
            kbNum = rng.nextInt(in: 2900000...3199999)
        case .win10, .win11:
            kbNum = rng.nextInt(in: 5000000...5099999)
        }

        let kbId = "KB\(kbNum)"
        let category: UpdateCategory
        let title: String
        let dlSize: Double
        let instSize: Double

        if isSpecialRollup {
            category = .compatibility
            title = "Taskintosh Mac ↔ Windows Cultural Exchange Rollup (\(kbId))"
            dlSize = Double(rng.nextInt(in: 45...180)) + Double(rng.nextInt(in: 1...9)) * 0.1
            instSize = dlSize * Double(rng.nextInt(in: 18...25)) * 0.1
        } else {
            let catPick = rng.nextInt(in: 1...10)
            if catPick <= 5 {
                category = .security
                title = "Security Update for \(era.rawValue) (\(kbId))"
                dlSize = Double(rng.nextInt(in: 8...65)) + Double(rng.nextInt(in: 1...9)) * 0.1
                instSize = dlSize * 1.8
            } else if catPick <= 8 {
                category = .critical
                title = "Cumulative Servicing Stack Update for \(era.rawValue) (\(kbId))"
                dlSize = Double(rng.nextInt(in: 35...240)) + Double(rng.nextInt(in: 1...9)) * 0.1
                instSize = dlSize * 2.2
            } else {
                category = .driver
                title = "Update for \(era.rawValue) Dynamic Subsystem (\(kbId))"
                dlSize = Double(rng.nextInt(in: 3...30)) + Double(rng.nextInt(in: 1...9)) * 0.1
                instSize = dlSize * 1.4
            }
        }

        let allFiles = SystemFilenames.files(for: era)
        let sampleCount = min(3, allFiles.count)
        var components: [String] = []
        for _ in 0..<sampleCount {
            if let f = rng.choose(from: allFiles), !components.contains(f) {
                components.append(f)
            }
        }

        return FakeUpdateItem(
            kbIdentifier: kbId,
            title: title,
            category: category,
            downloadSizeMB: dlSize,
            installSizeMB: instSize,
            simulatedComponents: components
        )
    }
}
