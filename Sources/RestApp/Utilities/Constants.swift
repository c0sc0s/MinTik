import Foundation

extension Notification.Name {
    static let restAppStatusUpdate = Notification.Name("RestAppStatusUpdate")
    static let restAppRequestHide = Notification.Name("RestAppRequestHide")
    static let restAppNotificationStatusChanged = Notification.Name("RestAppNotificationStatusChanged")
}

func resourceURL(name: String, ext: String) -> URL? {
    // 1. Try main bundle (Contents/Resources)
    if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
    
    // 2. Try RestApp_RestApp.bundle inside Contents/Resources
    if let resourcePath = Bundle.main.resourceURL?.appendingPathComponent("RestApp_RestApp.bundle"),
       let bundle = Bundle(url: resourcePath),
       let url = bundle.url(forResource: name, withExtension: ext) {
        return url
    }
    
    return nil
}
