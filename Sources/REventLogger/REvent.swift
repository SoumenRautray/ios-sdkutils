import Foundation

struct REvent: Codable, Equatable {
    var eventType: EventType
    let appId: String
    let appName: String
    let appVersion: String
    let osVersion: String
    let deviceModel: String
    let deviceBrand: String
    let deviceName: String
    let sourceName: String
    let sourceVersion: String
    let errorCode: String
    let errorMessage: String
    let platform: String
    var eventVersion: String = "1.0"
    var occurrenceCount: Int = 1
    var firstOccurrenceOn: Double // unix time
    var info: [String: String]?

    init(_ eventType: EventType,
         sourceName: String,
         sourceVersion: String,
         errorCode: String,
         errorMessage: String,
         info: [String: String]? = nil) {
        let environment = REventLoggerEnvironment()
        self.appId = environment.appId
        self.appName = environment.appName
        self.appVersion = environment.appVersion
        self.platform = environment.devicePlatform
        self.osVersion = environment.deviceOsVersion
        self.deviceModel = environment.deviceModel
        self.deviceBrand = environment.deviceBrand
        self.deviceName = environment.deviceName
        self.firstOccurrenceOn = Date().timeIntervalSince1970
        self.eventType = eventType
        self.sourceName = sourceName
        self.sourceVersion = sourceVersion
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.info = info
    }
}

/// Describe the type of the event
enum EventType: String, Codable {
    case critical, warning
}

extension REvent {
    var eventId: String {
        let id = "\(eventType.rawValue)_\(String(describing: appVersion))_\(sourceName)_\(errorCode)_\(errorMessage)"
        return id.replacingOccurrences(of: " ", with: "_").lowercased()
    }

    mutating func updateOccurrenceCount() {
        occurrenceCount += 1
    }

    mutating func updateEventType(type: EventType) {
        eventType = type
    }
}
