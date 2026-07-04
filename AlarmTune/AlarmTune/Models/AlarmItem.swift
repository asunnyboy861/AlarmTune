import Foundation
import CoreData

@objc(AlarmItem)
public class AlarmItem: NSManagedObject, Identifiable {
    @NSManaged public var id: String?
    @NSManaged public var label: String?
    @NSManaged public var hour: Int16
    @NSManaged public var minute: Int16
    @NSManaged public var volume: Float
    @NSManaged public var soundName: String?
    @NSManaged public var isFadeIn: Bool
    @NSManaged public var fadeInDuration: Double
    @NSManaged public var isVibrate: Bool
    @NSManaged public var isEnabled: Bool
    @NSManaged public var isSnoozeEnabled: Bool
    @NSManaged public var snoozeDuration: Int16
    @NSManaged public var category: String?
    @NSManaged public var repeatDays: [Int]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var videoBackgroundName: String?  // M8.2 新增：视频背景标识
    @NSManaged public var videoVolume: Float  // V3 新增：视频音量 0.0...1.0，默认 0（静音）

    var wrappedId: String {
        id ?? UUID().uuidString
    }

    var wrappedLabel: String {
        label ?? "Alarm"
    }

    var wrappedSoundName: String {
        soundName ?? AppConstants.Sound.defaultSound
    }

    var wrappedCategory: String {
        category ?? ""
    }

    var fireDate: Date {
        Date.from(hour: Int(hour), minute: Int(minute))
    }

    var nextFireDate: Date? {
        let now = Date()
        let calendar = Calendar.current

        if let days = repeatDays, !days.isEmpty {
            var nearestDate: Date?
            for day in days {
                var components = DateComponents()
                components.hour = Int(hour)
                components.minute = Int(minute)
                // repeatDays uses 0=Sun...6=Sat, Calendar weekday uses 1=Sun...7=Sat
                components.weekday = day + 1

                if let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                    if nearestDate == nil || nextDate < nearestDate! {
                        nearestDate = nextDate
                    }
                }
            }
            return nearestDate
        }

        let todayFire = fireDate
        if todayFire > now {
            return todayFire
        }
        return calendar.date(byAdding: .day, value: 1, to: todayFire)
    }

    var formattedTime: String {
        let date = fireDate
        return date.formattedTime
    }

    var volumePercentage: Int {
        Int(volume * 100)
    }

    var volumeIcon: String {
        if volume == 0 { return "speaker.slash.fill" }
        if volume < 0.25 { return "speaker.fill" }
        if volume < 0.5 { return "speaker.wave.1.fill" }
        if volume < 0.75 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }
}

extension AlarmItem {
    enum AlarmCategory: String, CaseIterable {
        case work = "Work"
        case weekend = "Weekend"
        case important = "Important"
        case nap = "Nap"
        case medication = "Medication"

        var icon: String {
            switch self {
            case .work: return "briefcase.fill"
            case .weekend: return "sun.max.fill"
            case .important: return "exclamationmark.triangle.fill"
            case .nap: return "moon.fill"
            case .medication: return "pill.fill"
            }
        }

        var color: String {
            switch self {
            case .work: return "blue"
            case .weekend: return "orange"
            case .important: return "red"
            case .nap: return "indigo"
            case .medication: return "green"
            }
        }
    }

    static func create(in context: NSManagedObjectContext) -> AlarmItem {
        let alarm = AlarmItem(context: context)
        alarm.id = UUID().uuidString
        alarm.label = "Alarm"
        alarm.hour = 7
        alarm.minute = 0
        alarm.volume = AppConstants.Alarm.defaultVolume
        alarm.soundName = AppConstants.Sound.defaultSound
        alarm.isFadeIn = false
        alarm.fadeInDuration = AppConstants.Alarm.defaultFadeInDuration
        alarm.isVibrate = true
        alarm.isEnabled = true
        alarm.isSnoozeEnabled = true
        alarm.snoozeDuration = Int16(AppConstants.Alarm.defaultSnoozeMinutes)
        alarm.category = nil
        alarm.repeatDays = nil
        alarm.createdAt = Date()
        alarm.videoVolume = AppConstants.Alarm.defaultVideoVolume  // V3
        return alarm
    }
}
