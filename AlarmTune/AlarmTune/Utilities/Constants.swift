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
        // V3 新增：视频背景音量默认值（0 = 静音，向后兼容）
        static let defaultVideoVolume: Float = 0.0

        // W1 新增：默认音频来源（闹钟铃声模式，向后兼容）
        static let defaultAudioSource: String = "alarmSound"
    }

    /// W1 新增：视频闹钟音频来源枚举
    /// alarmSound = 闹钟铃声库（视频静音）
    /// videoSound = 视频原声（不播放闹钟铃声）
    enum AudioSource: String, CaseIterable, Identifiable {
        case alarmSound = "alarmSound"
        case videoSound = "videoSound"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .alarmSound: return "Alarm Sound"
            case .videoSound: return "Video Sound"
            }
        }

        var icon: String {
            switch self {
            case .alarmSound: return "bell.fill"
            case .videoSound: return "speaker.wave.2.fill"
            }
        }
    }

    enum Volume {
        static let minVolume: Float = 0.0
        static let maxVolume: Float = 1.0
        static let previewThrottleInterval: TimeInterval = 0.3
        // v2.0 新增：Fade-In 安全起始音量下限（F2-4）
        static let fadeInMinStartVolume: Float = 0.05
        // v2.0 新增：可听阈值，系统音量×闹钟音量低于此值时预警（F2-3）
        static let audibleThreshold: Float = 0.10
    }

    enum DayPicker {
        static let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]
        static let fullDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        static let weekdays = [1, 2, 3, 4, 5]
        static let weekends = [0, 6]
        static let allDays = [0, 1, 2, 3, 4, 5, 6]
    }

    enum Sound {
        /// 铃声分类，与 AlarmItem.AlarmCategory 风格对齐
        enum SoundCategory: String, CaseIterable, Identifiable {
            case loud = "Loud"
            case nature = "Nature"
            case gentle = "Gentle"
            case classic = "Classic"
            case fun = "Fun"

            var id: String { rawValue }

            var displayName: String { rawValue }

            var icon: String {
                switch self {
                case .loud:    return "speaker.wave.3.fill"
                case .nature:  return "leaf.fill"
                case .gentle:  return "cloud.sun.fill"
                case .classic: return "bell.fill"
                case .fun:     return "music.note.house.fill"
                }
            }

            /// 分类图标背景色，使用系统语义色，兼容深色模式
            var tint: String {
                switch self {
                case .loud:    return "red"
                case .nature:  return "green"
                case .gentle:  return "blue"
                case .classic: return "orange"
                case .fun:     return "purple"
                }
            }
        }

        /// 铃声来源类型，决定 urlForSound 的查找策略
        enum SoundSource: String {
            case builtIn = "builtIn"
            case appleMusic = "appleMusic"
            case imported = "imported"
        }

        /// 单个铃声的元数据描述
        struct SoundInfo: Identifiable, Hashable {
            let id: String
            let displayName: String
            let category: SoundCategory
            let source: SoundSource
            let isPremium: Bool

            static func builtIn(name: String, category: SoundCategory, isPremium: Bool = false) -> SoundInfo {
                SoundInfo(id: name, displayName: name, category: category, source: .builtIn, isPremium: isPremium)
            }
        }

        /// 根据 soundName 前缀推断来源类型
        static func source(for name: String) -> SoundSource {
            if name.hasPrefix("appleMusic:") { return .appleMusic }
            if name.hasPrefix("imported:")   { return .imported }
            return .builtIn
        }

        /// 随机铃声 Shuffle 模式（M8.1）
        /// 防止铃声疲劳：每天/每周自动从内置铃声中随机选择
        enum ShuffleMode: String, CaseIterable, Identifiable {
            case off = "off"
            case daily = "daily"
            case weekly = "weekly"

            var id: String { rawValue }

            var displayName: String {
                switch self {
                case .off:    return "Off"
                case .daily:  return "Change Daily"
                case .weekly: return "Change Weekly"
                }
            }

            var icon: String {
                switch self {
                case .off:    return "arrow.clockwise"
                case .daily:  return "calendar"
                case .weekly: return "calendar.badge.clock"
                }
            }
        }

        /// Shuffle 模式存储键
        static let shuffleModeKey = "alarmShuffleMode"
        static let shuffleLastChangeKey = "alarmShuffleLastChange"

        /// 从内置铃声中随机选择一首，排除当前铃声
        static func shuffleSound(excluding current: String) -> String {
            let pool = builtInSounds
                .map { $0.displayName }
                .filter { $0 != current }
            return pool.randomElement() ?? current
        }

        static let builtInSounds: [SoundInfo] = [
            // Loud
            .builtIn(name: "Emergency Siren",  category: .loud),
            .builtIn(name: "Air Horn",         category: .loud),
            .builtIn(name: "Car Alarm",        category: .loud),
            .builtIn(name: "Military Bugle",   category: .loud),
            .builtIn(name: "Fire Alarm",       category: .loud),
            .builtIn(name: "School Bell",      category: .loud),
            // Nature
            .builtIn(name: "Forest Birds",     category: .nature),
            .builtIn(name: "Ocean Waves",      category: .nature),
            .builtIn(name: "Rain Morning",     category: .nature),
            .builtIn(name: "Creek Stream",     category: .nature),
            .builtIn(name: "Wind Chime",       category: .nature),
            .builtIn(name: "Thunder Roll",     category: .nature),
            // Gentle
            .builtIn(name: "Gentle Morning",   category: .gentle),
            .builtIn(name: "Soft Bell",        category: .gentle),
            .builtIn(name: "Piano Lullaby",    category: .gentle),
            .builtIn(name: "Harp Dream",       category: .gentle),
            .builtIn(name: "Zen Bowl",         category: .gentle),
            .builtIn(name: "Sunrise Glow",     category: .gentle),
            // Classic
            .builtIn(name: "Classic Alarm",    category: .classic),
            .builtIn(name: "Digital Beep",     category: .classic),
            .builtIn(name: "Retro Ring",       category: .classic),
            .builtIn(name: "Mechanical Tick",  category: .classic),
            .builtIn(name: "Office Buzz",      category: .classic),
            .builtIn(name: "Old Telephone",    category: .classic),
            // Fun
            .builtIn(name: "Nature Chirp",     category: .fun),
            .builtIn(name: "Disco Wake",       category: .fun),
            .builtIn(name: "Sunny Day",        category: .fun),
            .builtIn(name: "Rhythm Beat",      category: .fun),
            .builtIn(name: "Cheerful Tune",    category: .fun),
            .builtIn(name: "Morning Coffee",   category: .fun),
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

    enum Theme {
        static let storageKey = "appTheme"
    }

    enum Layout {
        static let maxContentWidth: CGFloat = 600
        static let cardCornerRadius: CGFloat = 16
        static let largeCardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let largeCardPadding: CGFloat = 24
    }
}
