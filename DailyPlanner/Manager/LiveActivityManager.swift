import Foundation
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    @available(iOS 16.1, *)
    private var currentActivity: Activity<DailyPlannerAttributes>? {
        return Activity<DailyPlannerAttributes>.activities.first
    }
    
    func startActivity(activeTimer: String?, timerEnd: Date?, selectedHabits: [HabitSummary]) {
        if #available(iOS 16.1, *) {
            // End any existing activity first
            endActivity()
            
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            
            let attributes = DailyPlannerAttributes(name: "Daily Planner")
            let contentState = DailyPlannerAttributes.ContentState(
                activeTimerHabit: activeTimer,
                timerEndTime: timerEnd,
                selectedHabits: selectedHabits
            )
            
            let content = ActivityContent(state: contentState, staleDate: nil)
            
            do {
                let _ = try Activity.request(attributes: attributes, content: content)
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
    }
    
    func updateActivity(activeTimer: String?, timerEnd: Date?, selectedHabits: [HabitSummary]) {
        if #available(iOS 16.1, *) {
            Task {
                guard let activity = currentActivity else {
                    // If no activity is active, just start one.
                    startActivity(activeTimer: activeTimer, timerEnd: timerEnd, selectedHabits: selectedHabits)
                    return
                }
                
                let contentState = DailyPlannerAttributes.ContentState(
                    activeTimerHabit: activeTimer,
                    timerEndTime: timerEnd,
                    selectedHabits: selectedHabits
                )
                let content = ActivityContent(state: contentState, staleDate: nil)
                
                await activity.update(content)
            }
        }
    }
    
    func endActivity() {
        if #available(iOS 16.1, *) {
            Task {
                for activity in Activity<DailyPlannerAttributes>.activities {
                    let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
                    await activity.end(finalContent, dismissalPolicy: .immediate)
                }
            }
        }
    }
}
