import Foundation
import UIKit

public protocol EventDescriptor: AnyObject {
    var startDate: Date {get set}
    var endDate: Date {get set}
    var isAllDay: Bool {get}
    var text: String {get}
    var attributedText: NSAttributedString? {get}
    var lineBreakMode: NSLineBreakMode? {get}
    var font: UIFont {get}
    var color: UIColor {get}
    var textColor: UIColor {get}
    var borderColor: UIColor {get}
    var borderWidth: CGFloat {get}
    var backgroundColor: UIColor {get}
    var editedEvent: EventDescriptor? {get set}
    var descriptionText: String {get}
    var descriptionFont: UIFont {get}
    var descriptionColor: UIColor {get}
    func makeEditable() -> Self
    func commitEditing()
}
