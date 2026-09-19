import Foundation

final class UsageHistory {
    private let defaults: UserDefaults
    private let key = "swoop.usage.v1"
    private var records: [String: Record]

    struct Record: Codable {
        var count: Int
        var lastUsed: Date
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: Record].self, from: data) {
            records = decoded
        } else {
            records = [:]
        }
    }

    func record(actionID: String) {
        var item = records[actionID] ?? Record(count: 0, lastUsed: Date())
        item.count += 1
        item.lastUsed = Date()
        records[actionID] = item
        persist()
    }

    func snapshot(actionID: String) -> UsageSnapshot {
        guard let item = records[actionID] else {
            return UsageSnapshot(count: 0, lastUsed: nil)
        }
        return UsageSnapshot(count: item.count, lastUsed: item.lastUsed)
    }

    func recentActionIDs(limit: Int) -> [String] {
        records.sorted { lhs, rhs in
            if lhs.value.lastUsed != rhs.value.lastUsed {
                return lhs.value.lastUsed > rhs.value.lastUsed
            }
            return lhs.value.count > rhs.value.count
        }
        .prefix(limit)
        .map(\.key)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: key)
        }
    }
}
