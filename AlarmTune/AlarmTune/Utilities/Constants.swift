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
        // V3 新增：视频背景音量默认值（0.55 = 55%，与闹钟音量一致）
        // W5：从 0.0 改为 0.55，避免用户选择视频后预览/响铃无声
        static let defaultVideoVolume: Float = 0.55

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

    /// R4 新增：可靠性相关常量
    /// 命名空间模式继承自 Alarm、Sound、Volume 等现有子命名空间
    enum Reliability {
        /// 后台保活开关的 UserDefaults 存储键
        /// 命名规范继承自 shuffleModeKey（alarm*Key 模式）
        static let backgroundKeepAliveKey = "alarmBackgroundKeepAlive"

        /// 后台保活默认值：true（默认开启，优先保障闹钟可靠性）
        static let defaultBackgroundKeepAlive: Bool = true

        /// 静音模式可靠性等级（用于 R5 指示器展示）
        enum ReliabilityLevel: String {
            case reliable     // 后台保活开启 + 内置铃声 -> 静音模式可响
            case partial      // 后台保活关闭 或 Apple Music 铃声 -> 仅非静音模式可响
            case atRisk       // 系统音量为0 或 静音模式 + 无保活 -> 可能不响

            var displayName: String {
                switch self {
                case .reliable: return "Reliable in silent mode"
                case .partial:  return "May not ring in silent mode"
                case .atRisk:   return "Alarm may not sound"
                }
            }

            var icon: String {
                switch self {
                case .reliable: return "checkmark.shield.fill"
                case .partial:  return "exclamationmark.shield.fill"
                case .atRisk:   return "xmark.shield.fill"
                }
            }

            var tint: String {
                switch self {
                case .reliable: return "green"
                case .partial:  return "orange"
                case .atRisk:   return "red"
                }
            }
        }
    }

    enum Layout {
        static let maxContentWidth: CGFloat = 600
        static let cardCornerRadius: CGFloat = 16
        static let largeCardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let largeCardPadding: CGFloat = 24
    }

    /// M9 新增：Typography 命名空间（与 Apple HIG Type Scale 对齐）
    /// 用于 dynamicFont(_:relativeTo:) 修饰器的语义化基准字号
    enum Typography {
        /// 动态字号类型（与 Apple HIG Type Scale 对齐）
        enum Size {
            static let largeTitle: CGFloat = 34
            static let title: CGFloat = 28
            static let title2: CGFloat = 22
            static let title3: CGFloat = 20
            static let headline: CGFloat = 17
            static let body: CGFloat = 17
            static let callout: CGFloat = 16
            static let subheadline: CGFloat = 15
            static let footnote: CGFloat = 13
            static let caption: CGFloat = 12
            static let caption2: CGFloat = 11
        }

        /// 闹钟时间字号（特殊场景，使用 fixedFont 不随 Dynamic Type 缩放）
        /// 原因：闹钟时间是视觉主体，过大缩放会破坏布局
        static let alarmTimeBaseSize: CGFloat = 48  // isPad 时 64
        static let ringTimeBaseSize: CGFloat = 60   // isPad 时 80
    }
}
