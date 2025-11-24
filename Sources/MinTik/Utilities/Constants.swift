import Foundation

extension Notification.Name {
    static let MinTikStatusUpdate = Notification.Name("MinTikStatusUpdate")
    static let MinTikRequestHide = Notification.Name("MinTikRequestHide")
    static let MinTikNotificationStatusChanged = Notification.Name("MinTikNotificationStatusChanged")
}

func resourceURL(name: String, ext: String) -> URL? {
    // 1. Try main bundle (Contents/Resources)
    if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
    
    // 2. Try MinTik_MinTik.bundle inside Contents/Resources
    if let resourcePath = Bundle.main.resourceURL?.appendingPathComponent("MinTik_MinTik.bundle"),
       let bundle = Bundle(url: resourcePath),
       let url = bundle.url(forResource: name, withExtension: ext) {
        return url
    }
    
    return nil
}
