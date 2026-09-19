import AppKit

final class CandidateListView: NSView {
    private var rows: [CandidateRowView] = []

    func render(_ items: [SearchResult], selectedIndex: Int, iconFor: (SearchResult) -> NSImage?) {
        while rows.count < items.count {
            let row = CandidateRowView()
            addSubview(row)
            rows.append(row)
        }
        while rows.count > items.count {
            rows.removeLast().removeFromSuperview()
        }
        for (index, item) in items.enumerated() {
            rows[index].configure(
                title: item.title,
                subtitle: item.subtitle,
                icon: iconFor(item),
                selected: index == selectedIndex
            )
        }
        needsLayout = true
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: CGFloat(rows.count) * LauncherLayout.rowHeight)
    }

    override func layout() {
        super.layout()
        for (index, row) in rows.enumerated() {
            row.frame = NSRect(
                x: 0,
                y: bounds.height - CGFloat(index + 1) * LauncherLayout.rowHeight,
                width: bounds.width,
                height: LauncherLayout.rowHeight
            )
        }
    }
}
