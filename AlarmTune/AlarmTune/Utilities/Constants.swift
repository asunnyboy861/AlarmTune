import Foundation

enum AppConstants {
    static let bundleId = "com.zzoutuo.AlarmTune"
    static let appName = "AlarmTune"
    static let feedbackAppName = "AlarmTune"
    static let feedbackEndpoint = "https://feedback-board.iocompile67692.workers.dev/api/feedback"
    static let supportURL = "https://asunnyboy861.github.io/AlarmTune-support/"
    static let privacyURL = "https://asunnyboy861.github.io/AlarmTune-privacy/"
    static let termsURL = "https://asunnyboy861.github.io/AlarmTune-terms/"
    static let contactEmail = "iocompile67692@gmail.com"

    enum Alarm {
        static let defaultSnoozeMinutes: Int = 5
        static let maxSnoozeCount: Int = 3
        static let defaultFadeInDuration: Double = 5.0
        static let defaultVolume: Float = 0.55
        static let minFadeInDuration: Double = 1.0
        static let maxFadeInDuration: Double = 30.0
        static let minSnoozeDuration: Int = 1
        static let maxSnoozeDuration: Int = 30
    }

    enum Volume {
        static let minVolume: Float = 0.0
        static let maxVolume: Float = 1.0
        static let previewThrottleInterval: TimeInterval = 0.3
    }

    enum DayPicker {
        static let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]
        static let fullDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        static let weekdays = [1, 2, 3, 4, 5]
        static let weekends = [0, 6]
        static let allDays = [0, 1, 2, 3, 4, 5, 6]
    }

    enum Sound {
        static let builtInSounds = [
            "Gentle Morning",
            "Digital Beep",
            "Nature Chirp",
            "Soft Bell",
            "Classic Alarm"
        ]
        static let defaultSound = "Gentle Morning"
    }

    enum Feedback {
        static let subjects = [
            "Feature Request",
            "Bug Report",
            "Usage Question",
            "Performance Issue",
            "UI Suggestion",
            "Other"
        ]
        static let defaultSubject = "Other"
    }

    enum Layout {
        static let maxContentWidth: CGFloat = 600
        static let cardCornerRadius: CGFloat = 16
        static let largeCardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let largeCardPadding: CGFloat = 24
    }
}
