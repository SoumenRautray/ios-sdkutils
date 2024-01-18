import Quick
import Nimble
import Foundation

#if canImport(RSDKUtils)
@testable import RSDKUtils // Cocoapods version
#else
@testable import RSDKUtilsMain
@testable import REventLogger
#endif

class REventLoggerModuleSpec: QuickSpec {
    override func spec() {
        describe("Event Logger Module") {
            var mockEventsSender: REventSenderMock!
            var mockEventStorage: REventStorageMock!
            var mockEventsCache: REventsLoggerCacheMock!
            var eventLoggerModule: REventLoggerModule!
            let eventQueue = DispatchQueue(label: "eventLogger.test")
            beforeEach {
                mockEventsSender = REventSenderMock()
                mockEventStorage = REventStorageMock()
                mockEventsCache = REventsLoggerCacheMock()
                mockEventsSender.response = .success(Data())
                eventLoggerModule = REventLoggerModule(eventsStorage: mockEventStorage,
                                                   eventsSender: mockEventsSender,
                                                   eventsCache: mockEventsCache)
            }
            context("isEventValid method") {
                it("will return true for a valid event") {
                    let isvalid = eventLoggerModule.isEventValid("IAM", "7.2.0", "500", "Network Error")
                    expect(isvalid).to(beTrue())
                }
                it("will return false for a valid event") {
                    let isvalid = eventLoggerModule.isEventValid("", "", "", "")
                    expect(isvalid).toNot(beTrue())
                }
            }

            context("sendCriticalEvent method") {
                it("will store the critical event as a warning event after sending the event") {
                    let event = REventLoggerMockData.REventModel
                    waitUntil { done in
                        eventLoggerModule.sendCriticalEvent(event.eventId, event)
                        expect(mockEventStorage.getEventCount()).to(equal(1))
                        let storedEvent = mockEventStorage.retrieveEvent(event.eventId)
                        expect(storedEvent?.eventType.rawValue).to(equal("warning"))
                        done()
                    }
                }
            }

            context("sendAllEventsInStorage method") {
                it("will delete all the stored events after sending the events") {
                    mockEventStorage.insertOrUpdateEvent("event1", event: REventLoggerMockData.REventModel)
                    mockEventStorage.insertOrUpdateEvent("event2", event: REventLoggerMockData.REventModel2)
                    waitUntil { done in
                        expect(mockEventStorage.getEventCount()).to(equal(2))
                        eventLoggerModule.sendAllEventsInStorage(deleteOldEventsOnFailure: true)
                        expect(mockEventStorage.getEventCount()).to(equal(0))
                        done()
                    }
                }
            }
            context("sendEventIfNeeded method") {
                it("will send the critical event if new critical event is logged ") {
                    waitUntil { done in
                        let event = REventLoggerMockData.REventModel
                        eventLoggerModule.sendEventIfNeeded(.critical, event.eventId, event, true)
                        expect(mockEventStorage.getEventCount()).to(equal(1))
                        let storedEvent = mockEventStorage.retrieveEvent(event.eventId)
                        expect(storedEvent?.eventType.rawValue).to(equal("warning"))
                        done()
                    }
                }
                it("will send the critical event if new critical event is logged ") {
                    waitUntil { done in
                        mockEventStorage.insertOrUpdateEvent("event1", event: REventLoggerMockData.REventModel)
                        mockEventStorage.insertOrUpdateEvent("event2", event: REventLoggerMockData.REventModel2)
                        let newEvent = REventLoggerMockData.REventModel
                        eventLoggerModule.sendEventIfNeeded(.critical, newEvent.eventId, newEvent, true, maxEventCount: 2)
                        expect(mockEventStorage.getEventCount()).to(equal(0))
                        done()
                    }
                }
            }
            context("isTtlExpired method") {
                it("will return true if the diffence between current time and reference time is more than ttl expiry time") {
                    mockEventsCache.setTtlReferenceTime(REventLoggerMockData.mockRefTime)
                    expect(eventLoggerModule.isTtlExpired()).to(equal(true))
                }
                it("will return false if the diffence between current time and reference time is less than ttl expiry time") {
                    mockEventsCache.setTtlReferenceTime(REventLoggerMockData.mockRefTime2)
                    expect(eventLoggerModule.isTtlExpired()).to(equal(false))
                }
            }
            context("configure method") {
                it("will configure the api key and api url if valid value is sent") {
                    eventLoggerModule.configure(apiConfiguration: EventLoggerConfiguration(apiKey: REventLoggerMockData.apiKey,
                                                                             apiUrl: REventLoggerMockData.apiUrl))
                    expect(mockEventsSender.didConfigure).to(beTrue())
                }
                it("will not configure api Key and url if valid values is not sent") {
                    eventLoggerModule.configure(apiConfiguration: nil)
                    expect(mockEventsSender.didConfigure).to(beFalse())
                }
            }
        }
    }
}
