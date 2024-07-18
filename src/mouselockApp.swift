import SwiftUI

@main
struct mouselockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState();

    @Published var games: Dictionary<String, String> = [
        "com.riotgames.LeagueofLegends.GameClient": "1/League of Legends",
        "tv.parsec.www": "2/Parsec",
        "com.riotgames.LeagueofLegends.LeagueClient": "3/League Client",
        "net.whatsapp.WhatsApp": "4/WhatsApp",
    ];

    @Published var width: String = UserDefaults.standard.string(forKey: "width") ?? "1920" {
        didSet {UserDefaults.standard.set(self.width, forKey: "width")}
    };
    @Published var height: String = UserDefaults.standard.string(forKey: "height") ?? "1080" {
        didSet {UserDefaults.standard.set(self.height, forKey: "height")}
    };
    @Published var active: Bool = UserDefaults.standard.bool(forKey: "active") {
        didSet {UserDefaults.standard.set(self.active, forKey: "active")}
    };
    @Published var activegames: Dictionary<String, Bool> = UserDefaults.standard.dictionary(forKey: "activegames") as? [String: Bool] ?? [:] {
        didSet {UserDefaults.standard.set(self.activegames, forKey: "activegames")}
    };
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var lastTime: TimeInterval = 0;
    var lastDeltaX: CGFloat = 0;
    var lastDeltaY: CGFloat = 0;

    func applicationDidFinishLaunching(_ notification: Notification) {

        // remove stale games from activegames
        for (key, _) in AppState.shared.activegames {
            if (AppState.shared.games[key] == nil) {
                AppState.shared.activegames.removeValue(forKey: key);
            }
        }

        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged], handler: {(event: NSEvent) in
            if (self.lastTime != 0) { // ignore old events
                if (event.timestamp <= self.lastTime) {
                    self.lastDeltaX = 0;
                    self.lastDeltaY = 0;
                    return;
                }
            }

            // pause if not activated
            if (AppState.shared.active == false && (AppState.shared.activegames[(NSWorkspace().frontmostApplication?.bundleIdentifier ?? "")] ?? false) == false) {
                return;
            }

            let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
            let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
            let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]
            let currentPID = NSWorkspace().frontmostApplication?.processIdentifier
//            let info = windowInfoList?[0]
            let info = windowInfoList?.first { info in
              return (info["kCGWindowOwnerPID"] as! UInt32) == currentPID!
            }
            let pos = NSEvent.mouseLocation
            let deltaX = event.deltaX - self.lastDeltaX;
            let deltaY = event.deltaY - self.lastDeltaY;
            let mouseY = pos.flipped.y + deltaY
            let mouseX = pos.x + deltaX

            let windowHeight = CGFloat((info?["kCGWindowBounds"] as? [String: NSNumber])?["Height"]?.doubleValue ?? 0)
            let windowWidth = CGFloat((info?["kCGWindowBounds"] as? [String: NSNumber])?["Width"]?.doubleValue ?? 0)
            let windowX = CGFloat((info?["kCGWindowBounds"] as? [String: NSNumber])?["X"]?.doubleValue ?? 0)
            let windowY = CGFloat((info?["kCGWindowBounds"] as? [String: NSNumber])?["Y"]?.doubleValue ?? 0)

            let pointX = clamp(mouseX, minValue: windowX + 2, maxValue: windowX + windowWidth - 2);
            let pointY = clamp(mouseY, minValue: windowY + 2, maxValue: windowY + windowHeight - 2);

            self.lastDeltaX = deltaX
            self.lastDeltaY = deltaY

//            print("windowX: ", windowX,
//                  ", windowY: ", windowY,
//                  ", windowWidth: ", windowWidth,
//                  ", windowHeight: ", windowHeight,
//                  ", pointX: ", pointX,
//                  ", pointY: ", pointY,
//                  ", mPosX: ", pos.x,
//                  ", mPosY: ", pos.y,
//                  ", mouseX: ", mouseX,
//                  ", mouseY: ", mouseY )

            CGWarpMouseCursorPosition(CGPoint(x: pointX, y: pointY));

            self.lastTime = ProcessInfo.processInfo.systemUptime;
        });
    }
}


public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
    return min(max(value, minValue), maxValue)
}

extension NSPoint {
    var flipped: NSPoint {
        // let frame = (NSScreen.currentScreenForMouseLocation()?.frame)!
        let mainFrame = (NSScreen.main?.frame)!

        // print("mainFrameX: ", mainFrame.origin.x, ", mainFrameY: ", mainFrame.origin.y, ", frameX: ", frame.origin.x, ", frameY: ", frame.origin.y )

        var mainFrameHeight = mainFrame.origin.y

        if (mainFrameHeight == 0) {
            mainFrameHeight = mainFrame.size.height
        }

        let y = mainFrameHeight - self.y;

        return NSPoint(x: self.x, y: y)
    }
}

// extension NSScreen {
//     static func currentScreenForMouseLocation() -> NSScreen? {
//         let mouseLocation = NSEvent.mouseLocation
//         return screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
//     }
// }
