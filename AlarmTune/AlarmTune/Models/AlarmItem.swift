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
        let todayFire = fireDate

        if todayFire > now {
            return todayFire
        }

        return Calendar.current.date(byAdding: .day, value: 1, to: todayFire)
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
    enum VolumePreset: String, CaseIterable {
        case whisper = "Whisper"
        case gentle = "Gentle"
        case moderate = "Moderate"
        case loud = "Loud"
        case maximum = "Maximum"

        var volumeValue: Float {
            switch self {
            case .whisper: return 0.15
            case .gentle: return 0.30
            case .moderate: return 0.55
            case .loud: return 0.80
            case .maximum: return 1.0
            }
        }

        var icon: String {
            switch self {
            case .whisper: return "speaker.fill"
            case .gentle: return "speaker.wave.1.fill"
            case .moderate: return "speaker.wave.2.fill"
            case .loud: return "speaker.wave.3.fill"
            case .maximum: return "speaker.wave.3.fill"
            }
        }
    }

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
        return alarm
    }
}
