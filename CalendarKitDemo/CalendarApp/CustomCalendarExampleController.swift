import UIKit
import CalendarKit

class CustomCalendarExampleController: DayViewController {
  
  var data = [["Breakfast at Tiffany's",
               "New York, 5th avenue"],
              
              ["Workout",
               "Tufteparken"],
              
              ["Meeting with Alex",
               "Home",
               "Oslo, Tjuvholmen"],
              
              ["Beach Volleyball",
               "Ipanema Beach",
               "Rio De Janeiro"],
              
              ["WWDC",
               "Moscone West Convention Center",
               "747 Howard St"],
              
              ["Google I/O",
               "Shoreline Amphitheatre",
               "One Amphitheatre Parkway"],
              
              ["✈️️ to Svalbard ❄️️❄️️❄️️❤️️",
               "Oslo Gardermoen"],
              
              ["💻📲 Developing CalendarKit",
               "🌍 Worldwide"],
              
              ["Software Development Lecture",
               "Mikpoli MB310",
               "Craig Federighi"],
              
  ]
  
  var generatedEvents = [EventDescriptor]()
  var alreadyGeneratedSet = Set<Date>()
  
  var colors = [UIColor.blue,
                UIColor.purple,
                UIColor.green,
                UIColor.red]
  
  private lazy var rangeFormatter: DateIntervalFormatter = {
    let fmt = DateIntervalFormatter()
    fmt.dateStyle = .short
    fmt.timeStyle = .short
    
    return fmt
  }()
  
  override func loadView() {
    calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
    
    var style = CalendarStyle()
    style.presentation = .threeDays
    style.header.swipeLabel.backgroundColor = .white
    dayView = DayView(calendar: calendar, style: style)
    view = dayView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CalendarKit Demo"
    navigationController?.navigationBar.isTranslucent = false
    dayView.autoScrollToFirstEvent = true
    reloadData()
  }
  
  // MARK: EventDataSource
  
  override func eventsForDate(_ date: Date, presentation: TimelinePresentation) -> [EventDescriptor] {
    if !alreadyGeneratedSet.contains(date) {
      alreadyGeneratedSet.insert(date)
      generatedEvents.append(contentsOf: generateEventsForDate(date))
    }
    if (presentation == .threeDays) {
      for i in 1...2 {
        let addedDate = date.addingTimeInterval(60 * 60 * 24 * Double(i))
        if !alreadyGeneratedSet.contains(addedDate) {
          alreadyGeneratedSet.insert(addedDate)
          generatedEvents.append(contentsOf: generateEventsForDate(addedDate))
        }
      }
    }
    return generatedEvents
  }
  
  private func generateEventsForDate(_ date: Date) -> [EventDescriptor] {
    var workingDate = Calendar.current.date(byAdding: .hour, value: Int.random(in: 1...15), to: date)!
    var events = [Event]()
    
    for i in 0...4 {
      let event = Event()
      
      let duration = Int.random(in: 60 ... 160)
      event.startDate = workingDate
      event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: workingDate)!
      
      var info = data[Int(arc4random_uniform(UInt32(data.count)))]
      
      let timezone = dayView.calendar.timeZone
      print(timezone)
      
      info.append(rangeFormatter.string(from: event.startDate, to: event.endDate))
      event.text = "\(info[0])\n\(info[1])"
      event.descriptionText = info.last!
      event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
      event.isAllDay = Int(arc4random_uniform(2)) % 2 == 0
      event.lineBreakMode = .byTruncatingTail
      
      events.append(event)
      
      let nextOffset = Int.random(in: 40 ... 250)
      workingDate = Calendar.current.date(byAdding: .minute, value: nextOffset, to: workingDate)!
      event.userInfo = "\(String(i)) - \(info)"
    }
    
    print("Events for \(date)")
    return events
  }
  
  // MARK: DayViewDelegate
  
  private var createdEvent: EventDescriptor?
  
  override func dayViewDidSelectEventView(_ eventView: EventView) {
    guard let descriptor = eventView.descriptor as? Event else {
      return
    }
    print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")
  }
  
  override func dayViewDidLongPressEventView(_ eventView: EventView) {
    guard let descriptor = eventView.descriptor as? Event else {
      return
    }
    endEventEditing()
    print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    beginEditing(event: descriptor, animated: true)
    print(Date())
  }
  
  override func dayView(dayView: DayView, didTapTimelineAt date: Date) {
    endEventEditing()
    print("Did Tap at date: \(date)")
  }
  
  override func dayViewDidBeginDragging(dayView: DayView) {
    endEventEditing()
    print("DayView did begin dragging")
  }
  
  override func dayView(dayView: DayView, willMoveTo date: Date) {
    print("DayView = \(dayView) will move to: \(date)")
  }
  
  override func dayView(dayView: DayView, didMoveTo date: Date) {
    print("DayView = \(dayView) did move to: \(date)")
  }
  
  override func dayView(dayView: DayView, didLongPressTimelineAt date: Date) {
    print("Did long press timeline at date \(date)")
    // Cancel editing current event and start creating a new one
    endEventEditing()
    let event = generateEventNearDate(date)
    print("Creating a new event")
    create(event: event, animated: true)
    createdEvent = event
  }
  
  private func generateEventNearDate(_ date: Date) -> EventDescriptor {
    let duration = Int(arc4random_uniform(160) + 60)
    let startDate = Calendar.current.date(byAdding: .minute, value: -Int(CGFloat(duration) / 2), to: date)!
    let event = Event()
    
    event.startDate = startDate
    event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)!
    
    var info = data[Int(arc4random_uniform(UInt32(data.count)))]
    
    info.append(rangeFormatter.string(from: event.startDate, to: event.endDate))
    event.text = info.reduce("", {$0 + $1 + "\n"})
    event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
    event.editedEvent = event
    
    return event
  }
  
  override func dayView(dayView: DayView, didUpdate event: EventDescriptor) {
    print("did finish editing \(event)")
    print("new startDate: \(event.startDate) new endDate: \(event.endDate)")
    
    if let _ = event.editedEvent {
      event.commitEditing()
    }
    
    if let createdEvent = createdEvent {
      createdEvent.editedEvent = nil
      generatedEvents.append(createdEvent)
      self.createdEvent = nil
      endEventEditing()
    }
    
    reloadData()
  }
}
