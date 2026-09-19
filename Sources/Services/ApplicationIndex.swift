import AppKit

final class ApplicationIndex {
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
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ]
        var result: [InstalledApp] = []
        var seen = Set<String>()
        for root in roots {
            result.append(contentsOf: collect(from: root, seen: &seen, depth: 0))
        }
        let found = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        apps = found
        return found
    }

    private func collect(from directory: URL, seen: inout Set<String>, depth: Int) -> [InstalledApp] {
        let fm = FileManager.default
        guard depth <= 2, let items = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var found: [InstalledApp] = []
        for item in items {
            if item.pathExtension == "app" {
                if let app = inspect(item), seen.insert(app.bundleIdentifier).inserted {
                    found.append(app)
                }
            } else if depth < 2 {
                found.append(contentsOf: collect(from: item, seen: &seen, depth: depth + 1))
            }
        }
        return found
    }

    private func inspect(_ url: URL) -> InstalledApp? {
        guard let bundle = Bundle(url: url) else { return nil }
        let identifier = bundle.bundleIdentifier ?? url.lastPathComponent
        let display = FileManager.default.displayName(atPath: url.path)
        let bundleName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
        let name = display.isEmpty ? (bundleName ?? url.deletingPathExtension().lastPathComponent) : display
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        return InstalledApp(name: name, bundleIdentifier: identifier, url: url, icon: icon)
    }
}
