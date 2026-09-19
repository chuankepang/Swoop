import AppKit

final class LauncherView: NSView {
    let chrome = NSView()
    let effect = NSVisualEffectView()
    let input = SearchInputView()
    let list = CandidateListView()
    private let divider = NSBox()
    private let border = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.28
        layer?.shadowRadius = LayoutMetrics.shadowRadius
        layer?.shadowOffset = CGSize(width: 0, height: -6)

        chrome.wantsLayer = true
        chrome.layer?.cornerRadius = LayoutMetrics.cornerRadius
        chrome.layer?.masksToBounds = true
        addSubview(chrome)

        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.isEmphasized = true
        effect.appearance = nil
        chrome.addSubview(effect)

        border.wantsLayer = true
        border.layer?.cornerRadius = LayoutMetrics.cornerRadius
        border.layer?.borderWidth = LayoutMetrics.hairline
        chrome.addSubview(border)

        divider.boxType = .separator
        chrome.addSubview(input)
        chrome.addSubview(divider)
        chrome.addSubview(list)
        updateHairline()
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateHairline()
        layer?.shadowOpacity = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? 0.45 : 0.22
    }

    private func updateHairline() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            border.layer?.borderColor = NSColor.labelColor.withAlphaComponent(0.12).cgColor
        }
    }

    override func layout() {
        super.layout()
        chrome.frame = bounds
        border.frame = chrome.bounds
        input.frame = NSRect(
            x: 0,
            y: chrome.bounds.height - LayoutMetrics.inputRowHeight,
            width: chrome.bounds.width,
            height: LayoutMetrics.inputRowHeight
        )
        let hasList = list.intrinsicContentSize.height > 0
        divider.isHidden = !hasList
        divider.frame = NSRect(
            x: LayoutMetrics.padding,
            y: input.frame.minY - 1,
            width: chrome.bounds.width - LayoutMetrics.padding * 2,
            height: 1
        )
        list.frame = NSRect(
            x: 0,
            y: 6,
            width: chrome.bounds.width,
            height: max(0, (hasList ? divider.frame.minY : input.frame.minY) - 8)
        )
    }
}
