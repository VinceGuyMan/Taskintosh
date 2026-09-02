import AppKit
import Combine

public final class DisplayManager: ObservableObject {
    public static let shared = DisplayManager()

    @Published public private(set) var screens: [NSScreen] = []
    @Published public var selectedScreenIndex: Int = 0

    private var cancellables = Set<AnyCancellable>()

    public init() {
        refreshScreens()

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshScreens()
            }
            .store(in: &cancellables)
    }

    public func refreshScreens() {
        self.screens = NSScreen.screens
        if selectedScreenIndex >= screens.count {
            selectedScreenIndex = 0
        }
    }

    public var currentScreen: NSScreen {
        if selectedScreenIndex < screens.count {
            return screens[selectedScreenIndex]
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    /// Computes the frame for the taskbar on the target screen.
    public func frame(for edge: TaskbarEdge, height: CGFloat, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame

        switch edge {
        case .bottom:
            return NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: height
            )
        case .top:
            return NSRect(
                x: screenFrame.minX,
                y: screenFrame.maxY - height,
                width: screenFrame.width,
                height: height
            )
        case .left:
            return NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: height,
                height: screenFrame.height
            )
        case .right:
            return NSRect(
                x: screenFrame.maxX - height,
                y: screenFrame.minY,
                width: height,
                height: screenFrame.height
            )
        }
    }
}
