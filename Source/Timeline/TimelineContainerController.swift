import UIKit

public final class TimelineContainerController: UIViewController {
    /// Content Offset to be set once the view size has been calculated
    public var pendingContentOffset: CGPoint?
    
    public lazy var timeline = TimelineView(style: .init(presentation: .oneDay))
    public lazy var container: TimelineContainer = {
        let view = TimelineContainer(timeline)
        view.addSubview(timeline)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        return view
    }()
    public lazy var header: DayHeaderView = {
        let view = DayHeaderView(calendar: calendar, style: style.header)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        return view
    }()
    
    private var style: CalendarStyle
    private var calendar: Calendar
    
    init(
        style: CalendarStyle,
        calendar: Calendar
    ) {
        self.style = style
        self.calendar = calendar
        super.init(nibName: nil, bundle: nil)
        constrainSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        container.contentSize = timeline.frame.size
        if let newOffset = pendingContentOffset {
            // Apply new offset only once the size has been determined
            if view.bounds != .zero {
                container.setContentOffset(newOffset, animated: false)
                container.setNeedsLayout()
                pendingContentOffset = nil
            }
        }
    }
    
    private func constrainSubviews() {
        let constraints: [NSLayoutConstraint] = [
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: style.presentation == .oneDay ? 32 : 64),
            container.topAnchor.constraint(equalTo: header.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
