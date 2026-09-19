import AppKit

final class ApplicationIndex {
    private static let extraBundleIdentifiers = [
        "com.apple.finder",
        "com.apple.Safari",
        "com.apple.systempreferences",
        "com.apple.Preview",
        "com.apple.Terminal",
        "com.apple.Safari.WebApp",
    ]
    private let queue = DispatchQueue(label: "local.swoop.apps", qos: .userInitiated)
    private(set) var apps: [InstalledApp] = []

    func scan(completion: @escaping ([InstalledApp]) -> Void) {
        queue.async {
            let found = self.scanNow()
            DispatchQueue.main.async {
                completion(found)
            }
        }
    }

    func scanNow() -> [InstalledApp] {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ]
        var result: [InstalledApp] = []
        var seen = Set<String>()
        for root in roots {
            result.append(contentsOf: collect(from: root, seen: &seen, depth: 0))
        }
        for identifier in Self.extraBundleIdentifiers {
            guard seen.contains(identifier) == false,
                  let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier),
                  let app = inspect(url) else { continue }
            seen.insert(identifier)
            result.append(app)
        }
        let found = result.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        apps = found
        return found
    }

    private func collect(from directory: URL, seen: inout Set<String>, depth: Int) -> [InstalledApp] {
        let fm = FileManager.default
        guard depth <= 2, let items = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var found: [InstalledApp] = []
        for item in items {
            let resolved = item.resolvingSymlinksInPath()
            if resolved.pathExtension == "app" {
                if let app = inspect(resolved), seen.insert(app.bundleIdentifier).inserted {
                    found.append(app)
                }
            } else if depth < 2 {
                found.append(contentsOf: collect(from: resolved, seen: &seen, depth: depth + 1))
            }
        }
        return found
    }

    private func inspect(_ url: URL) -> InstalledApp? {
        guard let bundle = Bundle(url: url) else { return nil }
        let identifier = bundle.bundleIdentifier ?? url.lastPathComponent
        var names: [String] = [
            url.deletingPathExtension().lastPathComponent,
            FileManager.default.displayName(atPath: url.path)
        ]
        for key in ["CFBundleDisplayName", "CFBundleName"] {
            if let value = bundle.object(forInfoDictionaryKey: key) as? String {
                names.append(value)
            }
        }
        for localization in bundle.localizations {
            if let path = bundle.path(forResource: "InfoPlist", ofType: "strings", inDirectory: nil, forLocalization: localization),
               let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                if let value = dict["CFBundleDisplayName"] ?? dict["CFBundleName"] {
                    names.append(value)
                }
            }
        }
        let uniqueNames = Array(Set(names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }))
        let display = FileManager.default.displayName(atPath: url.path)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 128, height: 128)
        return InstalledApp(
            displayName: display.isEmpty ? (uniqueNames.first ?? url.lastPathComponent) : display,
            names: uniqueNames,
            bundleIdentifier: identifier,
            url: url,
            icon: icon
        )
    }
}
