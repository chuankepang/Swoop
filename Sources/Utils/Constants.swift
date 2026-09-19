import Foundation

enum AppIdentity {
    static let name = "Swoop"
    static let bundleIdentifier = "local.swoop.launcher"
    static let version = "0.1.0"
}

enum LauncherLayout {
    static let panelWidth: CGFloat = 640
    static let cornerRadius: CGFloat = 18
    static let iconSize: CGFloat = 28
    static let rowIconSize: CGFloat = 22
    static let rowHeight: CGFloat = 34
    static let maxVisibleRows = 6
    static let inputRowHeight: CGFloat = 52
    static let padding: CGFloat = 14
}

enum RankingWeights {
    static let exactAlias: Double = 1000
    static let exactTitle: Double = 940
    static let shortAliasPrefix: Double = 910
    static let firstWordPrefix: Double = 880
    static let aliasPrefix: Double = 820
    static let titlePrefix: Double = 760
    static let wordInitials: Double = 720
    static let wordPrefix: Double = 640
    static let pinyin: Double = 900
    static let keyword: Double = 520
    static let subsequence: Double = 280
    static let maxUsageBonus: Double = 70
    static let maxRecencyBonus: Double = 25
}
