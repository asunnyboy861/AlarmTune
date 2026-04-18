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
}
