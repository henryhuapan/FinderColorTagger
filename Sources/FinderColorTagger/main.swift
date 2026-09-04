import AppKit
import SwiftUI

@main
struct FinderColorTaggerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var finderTrackingTimer: Timer?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var screenObserver: NSObjectProtocol?
    private var lastAppliedPanelFrame: NSRect?
    private var lastExternalAppWasFinder = false
    private let finderBundleIdentifier = "com.apple.finder"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createMenu()
        createPanel()
        observeWorkspaceChanges()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        finderTrackingTimer?.invalidate()
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    private func createPanel() {
        let rootView = FloatingTaggerView()
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        let panelSize = NSSize(width: 178, height: 38)

        let panel = FloatingPanel(
            contentRect: topCenteredFrame(size: panelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        self.panel = panel
        startFinderWindowTracking()
        updateVisibilityForFrontmostApplication()
    }

    private func topCenteredFrame(size: NSSize) -> NSRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = visibleFrame.midX - (size.width / 2)
        let y = visibleFrame.maxY - size.height - 12
        return NSRect(origin: NSPoint(x: x, y: y), size: size)
    }

    private func startFinderWindowTracking() {
        finderTrackingTimer?.invalidate()
        let timer = Timer(timeInterval: 0.30, repeats: true) { [weak self] _ in
            self?.updateVisibilityForFrontmostApplication()
            self?.attachPanelToFinderTitleBar()
        }
        RunLoop.main.add(timer, forMode: .common)
        finderTrackingTimer = timer
        refreshPanelAttachment()
    }

    private func attachPanelToFinderTitleBar() {
        guard let panel, panel.isVisible else { return }

        do {
            guard let finderWindow = try FinderWindowReader.frontWindow() else {
                applyPanelFrame(topCenteredFrame(size: panel.frame.size))
                return
            }

            let frame = titleBarAttachedFrame(
                finderWindow: finderWindow,
                panelSize: panel.frame.size
            )
            applyPanelFrame(frame)
        } catch {
            applyPanelFrame(topCenteredFrame(size: panel.frame.size))
        }
    }

    private func observeWorkspaceChanges() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let workspaceNotifications: [NSNotification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
            NSWorkspace.activeSpaceDidChangeNotification
        ]

        workspaceObservers = workspaceNotifications.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.recoverPanelAfterSystemStateChange()
            }
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recoverPanelAfterSystemStateChange()
        }
    }

    private func updateVisibilityForFrontmostApplication() {
        guard let panel else { return }

        let frontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let thisBundleIdentifier = Bundle.main.bundleIdentifier

        if frontmostBundleIdentifier == finderBundleIdentifier {
            lastExternalAppWasFinder = true
            panel.orderFrontRegardless()
            return
        }

        if frontmostBundleIdentifier == thisBundleIdentifier, lastExternalAppWasFinder {
            panel.orderFrontRegardless()
            return
        }

        if frontmostBundleIdentifier != thisBundleIdentifier {
            lastExternalAppWasFinder = false
        }

        panel.orderOut(nil)
    }

    private func applyPanelFrame(_ frame: NSRect) {
        guard let panel else { return }

        if let lastAppliedPanelFrame, framesAreEffectivelyEqual(lastAppliedPanelFrame, frame) {
            return
        }

        lastAppliedPanelFrame = frame
        panel.setFrame(frame, display: true, animate: false)
    }

    private func framesAreEffectivelyEqual(_ lhs: NSRect, _ rhs: NSRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) < 1 &&
        abs(lhs.origin.y - rhs.origin.y) < 1 &&
        abs(lhs.size.width - rhs.size.width) < 1 &&
        abs(lhs.size.height - rhs.size.height) < 1
    }

    private func recoverPanelAfterSystemStateChange() {
        startFinderWindowTracking()
        schedulePanelRefresh(after: 0.15)
        schedulePanelRefresh(after: 0.75)
        schedulePanelRefresh(after: 2.0)
    }

    private func schedulePanelRefresh(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.refreshPanelAttachment()
        }
    }

    private func refreshPanelAttachment() {
        reassertPanelWindowSettings()
        updateVisibilityForFrontmostApplication()
        attachPanelToFinderTitleBar()
    }

    private func reassertPanelWindowSettings() {
        guard let panel else { return }

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
    }

    private func titleBarAttachedFrame(finderWindow: FinderWindowInfo, panelSize: NSSize) -> NSRect {
        let screen = screen(containing: finderWindow.bounds) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let screenFrame = screen?.frame ?? visibleFrame
        let centeredX = finderWindow.bounds.midX - (panelSize.width / 2)
        let x = min(max(centeredX, visibleFrame.minX), visibleFrame.maxX - panelSize.width)

        let titleBarTopOffset: CGFloat = 7
        let topBasedY = finderWindow.bounds.minY + titleBarTopOffset
        let y = screenFrame.maxY - topBasedY - panelSize.height
        let clampedY = min(max(y, visibleFrame.minY), visibleFrame.maxY - panelSize.height)

        return NSRect(
            origin: NSPoint(x: x, y: clampedY),
            size: panelSize
        )
    }

    private func screen(containing topLeftBounds: CGRect) -> NSScreen? {
        NSScreen.screens.first { screen in
            let screenFrame = screen.frame
            let centerX = topLeftBounds.midX
            let cocoaCenterY = screenFrame.maxY - topLeftBounds.midY
            return screenFrame.contains(NSPoint(x: centerX, y: cocoaCenterY))
        }
    }

    private func createMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(
            withTitle: "Quit Finder Color Tagger",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "q" {
            NSApp.terminate(nil)
            return
        }

        super.keyDown(with: event)
    }
}

struct FloatingTaggerView: View {
    var body: some View {
        HStack(spacing: 5) {
            TagButton(title: "Red", color: .red) {
                toggleFinderLabel(.red)
            }

            TagButton(title: "Orange", color: .orange) {
                toggleFinderLabel(.orange)
            }

            TagButton(title: "Green", color: .green) {
                toggleFinderLabel(.green)
            }
        }
        .padding(5)
        .frame(width: 178, height: 38)
        .background(GlassBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)
        }
    }

    private func toggleFinderLabel(_ label: FinderLabel) {
        do {
            let count = try FinderTagger.toggle(label: label)
            if count <= 0 {
                NSSound.beep()
            }
        } catch {
            NSSound.beep()
        }
    }
}

struct TagButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.10))

                Image(systemName: "tag.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.82))
                    .padding(.bottom, 6)

                Capsule()
                    .fill(color)
                    .frame(width: 26, height: 4)
                    .padding(.bottom, 3)
            }
            .frame(width: 53, height: 29)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .help("Toggle \(title) Finder label")
        .buttonStyle(.plain)
    }
}

struct GlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

enum FinderLabel {
    case red
    case orange
    case green

    static let colorTagNames = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray", "Grey"]

    var title: String {
        switch self {
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .green:
            return "Green"
        }
    }
}

enum FinderTagger {
    static func toggle(label: FinderLabel) throws -> Int {
        let urls = try FinderSelectionReader.selectedURLs()
        guard !urls.isEmpty else {
            return 0
        }

        for url in urls {
            try toggle(label: label, for: url)
        }

        return urls.count
    }

    private static func toggle(label: FinderLabel, for url: URL) throws {
        let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
        var tags = resourceValues.tagNames ?? []

        if tags.contains(label.title) {
            tags.removeAll { $0 == label.title }
        } else {
            tags.removeAll { FinderLabel.colorTagNames.contains($0) }
            tags.append(label.title)
        }

        try (url as NSURL).setResourceValue(tags, forKey: .tagNamesKey)
    }
}

enum FinderSelectionReader {
    static func selectedURLs() throws -> [URL] {
        let source = """
        tell application "Finder"
            set selectedItems to selection
            set selectedPaths to {}
            repeat with selectedItem in selectedItems
                set end of selectedPaths to POSIX path of (selectedItem as alias)
            end repeat
            return selectedPaths
        end tell
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw FinderTaggerError.scriptCreationFailed
        }

        let result = script.executeAndReturnError(&error)
        if let error {
            throw FinderTaggerError.appleScriptFailed(error.description)
        }

        var urls: [URL] = []
        for index in 1...result.numberOfItems {
            guard let path = result.atIndex(index)?.stringValue else {
                continue
            }
            urls.append(URL(fileURLWithPath: path))
        }

        return urls
    }
}

enum FinderTaggerError: Error {
    case scriptCreationFailed
    case appleScriptFailed(String)
}

struct FinderWindowInfo {
    let title: String
    let bounds: CGRect
}

enum FinderWindowReader {
    static func frontWindow() throws -> FinderWindowInfo? {
        let source = """
        tell application "Finder"
            if (count of windows) is 0 then
                return missing value
            end if

            set windowName to name of front window
            set windowBounds to bounds of front window
            return {windowName, item 1 of windowBounds, item 2 of windowBounds, item 3 of windowBounds, item 4 of windowBounds}
        end tell
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw FinderTaggerError.scriptCreationFailed
        }

        let result = script.executeAndReturnError(&error)
        if let error {
            throw FinderTaggerError.appleScriptFailed(error.description)
        }

        guard result.descriptorType != typeNull else {
            return nil
        }

        let title = result.atIndex(1)?.stringValue ?? ""
        let left = CGFloat(result.atIndex(2)?.int32Value ?? 0)
        let top = CGFloat(result.atIndex(3)?.int32Value ?? 0)
        let right = CGFloat(result.atIndex(4)?.int32Value ?? 0)
        let bottom = CGFloat(result.atIndex(5)?.int32Value ?? 0)

        guard right > left, bottom > top else {
            return nil
        }

        return FinderWindowInfo(
            title: title,
            bounds: CGRect(x: left, y: top, width: right - left, height: bottom - top)
        )
    }
}
