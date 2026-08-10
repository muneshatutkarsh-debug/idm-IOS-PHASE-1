import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Starts / updates / ends the Dynamic Island + Lock Screen Live Activity.
final class LiveActivityController {

    static let shared = LiveActivityController()

    private init() {}

    #if canImport(ActivityKit)
    private var activities: [UUID: Activity<DownloadActivityAttributes>] = [:]

    private var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func state(for item: DownloadItem) -> DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(
            progress: item.progress,
            speedText: item.status == .completed ? "Done" : Formatters.speed(item.speed),
            etaText: item.status == .completed ? "Completed" : Formatters.eta(item.secondsRemaining),
            isCompleted: item.status == .completed
        )
    }

    func start(for item: DownloadItem, usesOriginalTheme: Bool = true) {
        guard activitiesEnabled, activities[item.id] == nil, !item.isSample else { return }

        let attributes = DownloadActivityAttributes(
            filename: item.filename,
            downloadId: item.id.uuidString,
            usesOriginalTheme: usesOriginalTheme
        )
        let initialState = state(for: item)

        do {
            let activity: Activity<DownloadActivityAttributes>
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: initialState, staleDate: nil),
                    pushType: nil
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: initialState,
                    pushType: nil
                )
            }
            activities[item.id] = activity
        } catch {
            // Live Activities can be disabled by the user - downloads still work.
            print("LiveActivity start failed: \(error.localizedDescription)")
        }
    }

    func update(_ item: DownloadItem) {
        guard let activity = activities[item.id] else { return }
        let newState = state(for: item)

        Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: newState, staleDate: nil))
            } else {
                await activity.update(using: newState)
            }
        }
    }

    func complete(_ item: DownloadItem) {
        guard let activity = activities[item.id] else { return }
        let finalState = state(for: item)
        activities[item.id] = nil

        Task {
            if #available(iOS 16.2, *) {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .after(Date().addingTimeInterval(6))
                )
            } else {
                await activity.end(using: finalState, dismissalPolicy: .default)
            }
        }
    }

    func end(id: UUID) {
        guard let activity = activities[id] else { return }
        activities[id] = nil

        Task {
            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }

    func endAll() {
        let all = activities
        activities.removeAll()
        Task {
            for (_, activity) in all {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }
    #else
    func start(for item: DownloadItem, usesOriginalTheme: Bool = true) {}
    func update(_ item: DownloadItem) {}
    func complete(_ item: DownloadItem) {}
    func end(id: UUID) {}
    func endAll() {}
    #endif
}
