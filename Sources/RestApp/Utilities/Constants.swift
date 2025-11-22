import Foundation

extension Notification.Name {
    static let restAppStatusUpdate = Notification.Name("RestAppStatusUpdate")
    static let restAppRequestHide = Notification.Name("RestAppRequestHide")
    static let restAppNotificationStatusChanged = Notification.Name("RestAppNotificationStatusChanged")
}

func resourceURL(name: String, ext: String) -> URL? {
    if let url = Bundle.module.url(forResource: name, withExtension: ext) { return url }
    if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
    if let base = Bundle.main.resourceURL { return base.appendingPathComponent("\(name).\(ext)") }
    return nil
}
