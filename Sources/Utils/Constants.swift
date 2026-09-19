import AppKit

enum AppIdentity {
    static let name = "Swoop"
    static let bundleIdentifier = "local.swoop.launcher"
    static let version = "0.1.0"
}

enum LayoutMetrics {
    static let scale: CGFloat = 1.26

    static let panelWidth: CGFloat = (640 * scale).rounded()
    static let cornerRadius: CGFloat = 22
    static let padding: CGFloat = (14 * scale).rounded()
    static let inputRowHeight: CGFloat = (56 * scale).rounded()
    static let iconSize: CGFloat = 44
    static let rowHeight: CGFloat = (48 * scale).rounded()
    static let rowIconSize: CGFloat = 32
    static let maxVisibleRows = 7
    static let titleSize: CGFloat = (16 * scale).rounded()
    static let subtitleSize: CGFloat = (12 * scale).rounded()
    static let inputSize: CGFloat = (21 * scale).rounded()
    static let stackSpacing: CGFloat = (12 * scale).rounded()
    static let hairline: CGFloat = 1
}

enum IconMetrics {
    static let canvas: CGFloat = 64
    static let tileCornerRadius: CGFloat = 14
    static let tileInset: CGFloat = 1
    static let candidateContainer: CGFloat = LayoutMetrics.rowIconSize
    static let stateContainer: CGFloat = LayoutMetrics.iconSize
    static let statusCanvas: CGFloat = 22
    static let statusGlyphSize: CGFloat = 18
    static let systemSymbolPointSize: CGFloat = 28
    static let systemContentInset: CGFloat = 3
    static let stateContentInset: CGFloat = 1
    static let statusContentInset: CGFloat = 1
}

enum RankingWeights {
    static let exactAlias: Double = 1000
    static let exactTitle: Double = 960
    static let exactNormalized: Double = 940
    static let prefix: Double = 860
    static let aliasPrefix: Double = 840
    static let wordInitials: Double = 760
    static let transliterationExact: Double = 900
    static let transliterationPrefix: Double = 780
    static let subsequence: Double = 280
    static let keyword: Double = 520
    static let strongMatch: Double = 700
    static let maxUsageBonus: Double = 70
    static let maxRecencyBonus: Double = 25
}
