import Foundation

#if canImport(RSDKUtils)
import RSDKUtils // Cocoapods version
#else
import RSDKUtilsMain
#endif

struct EventLoggerConfiguration {
    let apiKey: String
    let apiUrl: String
}

/// Event Logger that sends the custom events to the Event Logger Service
public final class REventLogger {
    /// Singleton shared instance of REventLogger
    public static let shared = REventLogger()
    internal private(set) var eventLogger: EventLoggerModule?
    private(set) var dependencyManager: TypedDependencyManager?
    var configuration: EventLoggerConfiguration?
    private var isConfigureCalled = false

    private init() { }

    /// Function to configure the Event Logger
    /// - Parameters:
    ///   - apiKey: your API Key
    ///   - apiUrl: a API Endpoint
    public func configure(apiKey: String?,
                          apiUrl: String?,
                          onCompletion: ((Bool, String) -> Void)? = nil) {
        guard configuration != nil else {
            Logger.debug("EventLogger is already configured")
            onCompletion?(true, "EventLogger is already configured")
            return
        }

        guard let apiKey = apiKey, let apiUrl = apiUrl else {
            onCompletion?(false, "EventLogger cannot be configured due to invalid api parameters")
            return
        }

        configuration = EventLoggerConfiguration(apiKey: apiKey, apiUrl: apiUrl)
        guard let configuration = configuration else {
            onCompletion?(false, "EventLogger cannot be configured due to invalid configuration")
            return
        }
        configureModules(dependencyManager: resolveDependency())
        eventLogger?.configure(apiConfiguration: configuration)
        isConfigureCalled = true
        //TODO: Implement App Life cycle
        if ((eventLogger?.isTtlExpired()) != nil) {
            eventLogger?.sendAllEventsInStorage()
        }

        onCompletion?(true, "EventLogger is configured")
    }

    /// Logs the critical event
    /// This event will be considered as high priority and will be sent immediately
    /// - Parameters:
    ///   - sourceName: Source name of the event e.g App name or SDK name
    ///   - sourceVersion: Version of the source e.g v1.0.0
    ///   - errorCode: Error code of the event, like custom error code or HTTP response error code
    ///   - errorMessage: Description of the error message.
    ///   - info: Any custom information. It's optional.
    public func sendCriticalEvent(sourceName: String,
                                  sourceVersion: String,
                                  errorCode: String,
                                  errorMessage: String,
                                  info: [String: String]? = nil) {
        if isConfigureCalled {
            eventLogger?.logEvent(EventType.critical, sourceName, sourceVersion, errorCode, errorMessage, info)
        }
    }

    /// Logs the warning event
    /// This event will be considered as low priority and will be sent with batch update.
    /// - Parameters:
    ///   - sourceName: Source name of the event e.g App name or SDK name
    ///   - sourceVersion: Version of the source e.g v1.0.0
    ///   - errorCode: Error code of the event, like custom error code or HTTP response error code
    ///   - errorMessage: Description of the error message.
    ///   - info: Any custom information. It's optional.
    public func sendWarningEvent(sourceName: String,
                                 sourceVersion: String,
                                 errorCode: String,
                                 errorMessage: String,
                                 info: [String: String]? = nil) {
        if isConfigureCalled {
            eventLogger?.logEvent(EventType.warning, sourceName, sourceVersion, errorCode, errorMessage, info)
        }
    }

    private func resolveDependency() -> TypedDependencyManager {
        let dependencyManager = TypedDependencyManager()
        let mainContainer = MainContainerFactory.create(dependencyManager: dependencyManager)
        dependencyManager.appendContainer(mainContainer)
        return dependencyManager
    }

    func configureModules(dependencyManager: TypedDependencyManager) {
        self.dependencyManager = dependencyManager
        guard let dataStorage = dependencyManager.resolve(type: REventDataCacheable.self),
              let eventsSender = dependencyManager.resolve(type: REventLoggerSendable.self),
              let eventsCache = dependencyManager.resolve(type: REventLoggerCacheable.self)
        else {
            Logger.debug("❌ Unable to resolve dependencies of EventLogger")
            return
        }
        eventLogger = EventLoggerModule(eventsStorage: dataStorage,
                                        eventsSender: eventsSender,
                                        eventsCache: eventsCache)
    }
}
