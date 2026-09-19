import AppKit

final class LauncherView: NSView {
    let effect = NSVisualEffectView()
    let input = SearchInputView()
    let list = CandidateListView()
    private let divider = NSBox()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = LauncherLayout.cornerRadius
        layer?.masksToBounds = true

        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.appearance = nil
        addSubview(effect)

        divider.boxType = .separator
        addSubview(input)
        addSubview(divider)
        addSubview(list)
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        effect.frame = bounds
        input.frame = NSRect(
            x: 0,
            y: bounds.height - LauncherLayout.inputRowHeight,
            width: bounds.width,
            height: LauncherLayout.inputRowHeight
        )
        let hasList = list.intrinsicContentSize.height > 0
        divider.isHidden = !hasList
        divider.frame = NSRect(
            x: 12,
            y: input.frame.minY - 1,
            width: bounds.width - 24,
            height: 1
        )
        list.frame = NSRect(
            x: 0,
            y: 4,
            width: bounds.width,
            height: max(0, (hasList ? divider.frame.minY : input.frame.minY) - 6)
        )
    }
}
