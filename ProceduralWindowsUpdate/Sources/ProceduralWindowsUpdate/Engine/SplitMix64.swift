import Foundation

/// Fast deterministic pseudo-random number generator based on the SplitMix64 algorithm.
/// Provides reproducible sequence generation from an arbitrary 64-bit seed.
public struct SplitMix64: Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        // Avoid 0 state weakness by mixing seed upfront
        var s = seed ^ 0x9E3779B97F4A7C15
        s = (s ^ (s >> 30)) &* 0xBF58476D1CE4E5B9
        s = (s ^ (s >> 27)) &* 0x94D049BB133111EB
        self.state = (s == 0) ? 0x853C49E6748FEA9B : s
    }

    /// Generates next pseudo-random 64-bit unsigned integer
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Returns a double uniformly distributed in [0.0, 1.0)
    public mutating func nextDouble() -> Double {
        let value = next() >> 11 // 53 bits
        return Double(value) / Double(1 << 53)
    }

    /// Returns an integer within the specified closed range
    public mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        guard range.lowerBound < range.upperBound else { return range.lowerBound }
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        let raw = next() % span
        return range.lowerBound + Int(raw)
    }

    /// Returns true with the given probability in [0.0, 1.0]
    public mutating func chance(_ probability: Double) -> Bool {
        guard probability > 0 else { return false }
        guard probability < 1 else { return true }
        return nextDouble() < probability
    }

    /// Randomly picks an element from an array
    public mutating func choose<T>(from array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        let idx = nextInt(in: 0...(array.count - 1))
        return array[idx]
    }

    /// Randomly picks an element based on relative weights
    public mutating func weightedChoose<T>(from items: [(item: T, weight: Double)]) -> T? {
        guard !items.isEmpty else { return nil }
        let totalWeight = items.reduce(0.0) { $0 + max(0.0, $1.weight) }
        guard totalWeight > 0 else { return items.first?.item }

        let target = nextDouble() * totalWeight
        var accumulated = 0.0
        for item in items {
            accumulated += max(0.0, item.weight)
            if accumulated >= target {
                return item.item
            }
        }
        return items.last?.item
    }

    /// Shuffles an array deterministically
    public mutating func shuffled<T>(_ array: [T]) -> [T] {
        var copy = array
        guard copy.count > 1 else { return copy }
        for i in (1..<copy.count).reversed() {
            let j = nextInt(in: 0...i)
            if i != j {
                copy.swapAt(i, j)
            }
        }
        return copy
    }
}
