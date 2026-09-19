import AppKit

final class LauncherView: NSView {
    let chromeClip = NSView()
    let effect = NSVisualEffectView()
    let wash = NSView()
    let input = SearchInputView()
    let list = CandidateListView()
    private let divider = NSBox()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false

        chromeClip.wantsLayer = true
        applyContinuousCorners(to: chromeClip)
        chromeClip.layer?.masksToBounds = true
        addSubview(chromeClip)

        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.isEmphasized = true
        effect.appearance = nil
        effect.wantsLayer = true
        applyContinuousCorners(to: effect)
        chromeClip.addSubview(effect)

        wash.wantsLayer = true
        applyContinuousCorners(to: wash)
        chromeClip.addSubview(wash)

        divider.boxType = .separator
        chromeClip.addSubview(input)
        chromeClip.addSubview(divider)
        chromeClip.addSubview(list)
        updateChromeColors()
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateChromeColors()
    }

    func setPresentedScale(_ scale: CGFloat) {
        guard let layer = chromeClip.layer else { return }
        let cx = chromeClip.bounds.midX
        let cy = chromeClip.bounds.midY
        layer.setAffineTransform(
            CGAffineTransform(translationX: cx, y: cy)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -cx, y: -cy)
        )
    }

    func resetPresentation() {
        chromeClip.layer?.setAffineTransform(.identity)
    }

    private func applyContinuousCorners(to view: NSView) {
        view.layer?.cornerRadius = LayoutMetrics.cornerRadius
        if #available(macOS 10.15, *) {
            view.layer?.cornerCurve = .continuous
        }
    }

    private func updateChromeColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            wash.layer?.backgroundColor = dark
                ? NSColor.black.withAlphaComponent(0.26).cgColor
                : NSColor.white.withAlphaComponent(0.30).cgColor
            chromeClip.layer?.borderWidth = LayoutMetrics.hairline * 0.5
            chromeClip.layer?.borderColor = NSColor.white.withAlphaComponent(dark ? 0.14 : 0.24).cgColor
        }
    }

    override func layout() {
        super.layout()
        chromeClip.frame = bounds
        effect.frame = chromeClip.bounds
        wash.frame = chromeClip.bounds
        input.frame = NSRect(
            x: 0,
            y: chromeClip.bounds.height - LayoutMetrics.inputRowHeight,
            width: chromeClip.bounds.width,
            height: LayoutMetrics.inputRowHeight
        )
        let hasList = list.intrinsicContentSize.height > 0
        divider.isHidden = !hasList
        divider.frame = NSRect(
            x: LayoutMetrics.padding,
            y: input.frame.minY - 1,
            width: chromeClip.bounds.width - LayoutMetrics.padding * 2,
            height: 1
        )
        list.frame = NSRect(
            x: 0,
            y: 6,
            width: chromeClip.bounds.width,
            height: max(0, (hasList ? divider.frame.minY : input.frame.minY) - 8)
        )
    }
}
