import Foundation

public enum GoalDataChangeNotifier {
    /// Posts a cross-process Darwin notification. Only call this from out-of-process
    /// contexts (e.g., widget intents). In-app mutations use the onMilestonesChanged
    /// callback chain via GoalDataRefreshCoordinator.connect.
    public static func post() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            notificationName,
            nil,
            nil,
            true
        )
    }

    public static func observe(_ handler: @escaping () -> Void) -> GoalDataChangeObservation {
        GoalDataChangeObservation(notificationName: notificationName, handler: handler)
    }

    private static var notificationName: CFNotificationName {
        CFNotificationName(AppIdentifiers.goalDataDidChangeNotification as CFString)
    }
}

public final class GoalDataChangeObservation {
    // Ownership: the box is +1 retained via passRetained and released in deinit.
    // The CF callback borrows with takeUnretainedValue since the observation outlives the observer.
    private let notificationName: CFNotificationName
    private let observer: UnsafeMutableRawPointer

    init(notificationName: CFNotificationName, handler: @escaping () -> Void) {
        self.notificationName = notificationName
        let box = GoalDataChangeObservationBox(handler: handler)
        observer = Unmanaged.passRetained(box).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let box = Unmanaged<GoalDataChangeObservationBox>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async { box.handler() }
            },
            notificationName.rawValue,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            notificationName,
            nil
        )
        Unmanaged<GoalDataChangeObservationBox>.fromOpaque(observer).release()
    }
}

private final class GoalDataChangeObservationBox {
    let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }
}
