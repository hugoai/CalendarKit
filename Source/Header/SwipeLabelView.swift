import UIKit

public final class SwipeLabelView: UIView, DayViewStateUpdating {
    public enum AnimationDirection {
        case Forward
        case Backward
        
        mutating func flip() {
            switch self {
            case .Forward:
                self = .Backward
            case .Backward:
                self = .Forward
            }
        }
    }
    
    public private(set) var calendar = Calendar.autoupdatingCurrent
    public weak var state: DayViewState? {
        willSet(newValue) {
            state?.unsubscribe(client: self)
        }
        didSet {
            state?.subscribe(client: self)
            updateLabelText()
        }
    }
    
    private var date: Date?
    
    private func updateLabelText() {
        guard let date = state?.selectedDate ?? self.date else { return }
        for (idx, label) in firstLabels.enumerated() {
            label.attributedText = formattedDate(date: date.addingTimeInterval(TimeInterval(idx * 60 * 60 * 24)))
        }
    }
    
    private var firstLabels: [UILabel] {
        headers.first!.subviews.compactMap{ $0 as? UILabel }
    }
    
    private var secondLabels: [UILabel] {
        headers.last!.subviews.compactMap{ $0 as? UILabel }
    }
    
    private var firstSeparators: [SeparatorView] {
        headers.first!.subviews.compactMap{ $0 as? SeparatorView }
    }
    
    private var secondSeparators: [SeparatorView] {
        headers.last!.subviews.compactMap{ $0 as? SeparatorView }
    }
    
    private var firstHeader: UIView {
        headers.first!
    }
    
    private var secondHeader: UIView {
        headers.last!
    }
    
    private var headers = [UIView]()
    
    private var style: SwipeLabelStyle
    
    private var presentation: TimelinePresentation = .oneDay
    
    public init(
        calendar: Calendar = Calendar.autoupdatingCurrent,
        style: SwipeLabelStyle,
        presentation: TimelinePresentation
    ) {
        self.calendar = calendar
        self.style = style
        super.init(frame: .zero)
        self.presentation = presentation
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func move(to date: Date) {
        state?.move(to: date)
        self.date = date
        updateLabelText()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let oneThird: CGFloat = (bounds.width - 60) / 3
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .none
        context?.saveGState()
        context?.setStrokeColor(style.separatorColor.cgColor)
        context?.setLineWidth(1)

        let startY: CGFloat = bounds.height / 2
        let endY: CGFloat = bounds.height
        let firstX: CGFloat = 60

        context?.beginPath()
        context?.move(to: CGPoint(x: firstX, y: startY))
        context?.addLine(to: CGPoint(x: firstX, y: endY))
        context?.strokePath()

        if presentation == .threeDays {
            let secondX: CGFloat = oneThird + 60
            let thirdX: CGFloat = oneThird * 2 + 60
            context?.beginPath()
            context?.move(to: CGPoint(x: secondX, y: startY))
            context?.addLine(to: CGPoint(x: secondX, y: endY))
            context?.strokePath()
            context?.beginPath()
            context?.move(to: CGPoint(x: thirdX, y: startY))
            context?.addLine(to: CGPoint(x: thirdX, y: endY))
            context?.strokePath()
        }

        context?.restoreGState()
    }
    
    private func configure() {
        backgroundColor = style.backgroundColor
        for i in 0...1 {
            let header = UIView()
            headers.append(header)
            header.tag = i + 2
            addSubview(header)
            if (presentation == .oneDay) {
                let label = UILabel()
                label.textAlignment = .center
                header.addSubview(label)
//                let separator = SeparatorView()
//                separator.backgroundColor = style.separatorColor
//                header.addSubview(separator)
            } else {
                for j in 0...2 {
                    let label = UILabel()
                    label.textAlignment = .center
                    label.tag = i*j
                    label.numberOfLines = 0
                    header.addSubview(label)
//                    let separator = SeparatorView()
//                    separator.backgroundColor = style.separatorColor
//                    header.addSubview(separator)
                }
            }
        }
        updateStyle(style)
    }
    
    public func updateStyle(_ newStyle: SwipeLabelStyle) {
        style = newStyle
        backgroundColor = style.backgroundColor
        setNeedsLayout()
    }
    
    private func animate(_ direction: AnimationDirection) {
        let multiplier: CGFloat = direction == .Forward ? -1 : 1
        let shiftRatio: CGFloat = 30/375
        let screenWidth = bounds.width
        
        secondHeader.alpha = 0
        secondHeader.frame = bounds
        secondHeader.frame.origin.x -= CGFloat(shiftRatio * screenWidth * 3) * multiplier
        
        UIView.animate(withDuration: 0.3, animations: {
            self.secondHeader.frame = self.bounds
            self.firstHeader.frame.origin.x += CGFloat(shiftRatio * screenWidth) * multiplier
            self.secondHeader.alpha = 1
            self.firstHeader.alpha = 0
        }, completion: { _ in
            self.headers = self.headers.reversed()
        })
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        for header in headers {
            header.frame = bounds
        }
        if presentation == .oneDay {
            constrainOneDayLabels()
        } else {
            constrainThreeDaysLabels()
        }
        constrainSeparators()
    }
    
    private func constrainOneDayLabels() {
        let firstLabel = firstLabels.first!
        let secondLabel = secondLabels.first!
        firstLabel.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            firstLabel.centerYAnchor.constraint(equalTo: firstHeader.centerYAnchor),
            firstLabel.centerXAnchor.constraint(equalTo: firstHeader.centerXAnchor, constant: 30),
            secondLabel.centerYAnchor.constraint(equalTo: secondHeader.centerYAnchor),
            secondLabel.centerXAnchor.constraint(equalTo: secondHeader.centerXAnchor, constant: 30),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func constrainThreeDaysLabels() {
        let third = (bounds.width - 60) / 3
        for (idx, label) in firstLabels.enumerated() {
            label.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                label.centerYAnchor.constraint(equalTo: firstHeader.centerYAnchor),
                label.centerXAnchor.constraint(equalTo: firstHeader.centerXAnchor, constant: CGFloat(idx - 1) * third + 30)
            ]
            NSLayoutConstraint.activate(constraints)
        }
        for (idx, label) in secondLabels.enumerated() {
            label.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                label.centerYAnchor.constraint(equalTo: secondHeader.centerYAnchor),
                label.centerXAnchor.constraint(equalTo: secondHeader.centerXAnchor, constant: CGFloat(idx - 1) * third + 30)
            ]
            NSLayoutConstraint.activate(constraints)
        }
    }
    
    private func constrainSeparators() {
        let height: CGFloat = presentation == .oneDay ? 16 : 24
        let width: CGFloat = 1
        let third = (bounds.width - 60) / 3
        for (idx, separator) in firstSeparators.enumerated() {
            separator.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                separator.widthAnchor.constraint(equalToConstant: width),
                separator.heightAnchor.constraint(equalToConstant: height),
                separator.bottomAnchor.constraint(equalTo: firstHeader.bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: firstHeader.leadingAnchor, constant: 60 + (third * CGFloat(idx)))
            ]
            NSLayoutConstraint.activate(constraints)
        }
        for (idx, separator) in secondSeparators.enumerated() {
            separator.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                separator.widthAnchor.constraint(equalToConstant: width),
                separator.heightAnchor.constraint(equalToConstant: height),
                separator.bottomAnchor.constraint(equalTo: secondHeader.bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: secondHeader.leadingAnchor, constant: 60 + (third * CGFloat(idx)))
            ]
            NSLayoutConstraint.activate(constraints)
        }
    }
    
    // MARK: DayViewStateUpdating
    
    public func move(from oldDate: Date, to newDate: Date) {
//        guard newDate != oldDate
//        else { return }
//        var direction: AnimationDirection = newDate > oldDate ? .Forward : .Backward
//        
//        let rightToLeft = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
//        if rightToLeft { direction.flip() }
//        
//        secondLabels.first!.attributedText = formattedDate(date: newDate)
//        if (presentation == .threeDays) {
//            secondLabels[1].attributedText = formattedDate(date: newDate.addingTimeInterval(60 * 60 * 24))
//            secondLabels[2].attributedText = formattedDate(date: newDate.addingTimeInterval(2 * 60 * 60 * 24))
//        }
//        
//        animate(direction)
    }
    
    private func formattedDate(date: Date) -> NSMutableAttributedString {
        let timezone = calendar.timeZone
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        formatter.timeZone = timezone
        formatter.locale = Locale.init(identifier: Locale.preferredLanguages[0])
        let attributedString = NSMutableAttributedString(string: formatter.string(from: date).uppercased())
        let textColor = calendar.isDateInToday(date) ? style.highlightedTextColor : style.textColor
        let textFont = calendar.isDateInToday(date) ? style.highlightedFont : style.font
        attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedString.length))
        if (presentation == .oneDay) {
            attributedString.addAttribute(.font, value: textFont, range: NSRange(location: 0, length: attributedString.length))
        } else if (presentation == .threeDays) {
            attributedString.replaceCharacters(in: NSRange.init(location: 3, length: 1), with: "\n")
            attributedString.addAttribute(.font, value: style.highlightedFont, range: NSRange(location: 0, length: attributedString.length))
            attributedString.addAttributes(
                [
                    NSAttributedString.Key.foregroundColor: textColor.withAlphaComponent(0.4),
                    NSAttributedString.Key.font: style.font
                ],
                range: NSRange(location: 0, length: 3)
            )
        }
        return attributedString
    }
}

final class SeparatorView: UIView {}
