import os.log

/// M12 新增：统一日志工具
/// 替代 print 语句，支持 Console.app 过滤与性能分析
/// 用法：AppLogger.audio.info("message"); AppLogger.persistence.error("message")
enum AppLogger {
    static let audio = Logger(subsystem: AppConstants.bundleId, category: "AudioService")
    static let alarm = Logger(subsystem: AppConstants.bundleId, category: "AlarmScheduler")
    static let persistence = Logger(subsystem: AppConstants.bundleId, category: "Persistence")
    static let volume = Logger(subsystem: AppConstants.bundleId, category: "VolumeManager")
    static let subscription = Logger(subsystem: AppConstants.bundleId, category: "Subscription")
    static let importService = Logger(subsystem: AppConstants.bundleId, category: "ImportService")
    static let app = Logger(subsystem: AppConstants.bundleId, category: "App")
    static let video = Logger(subsystem: AppConstants.bundleId, category: "Video")
    static let viewModel = Logger(subsystem: AppConstants.bundleId, category: "ViewModel")
    static let backgroundKeeper = Logger(subsystem: AppConstants.bundleId, category: "BackgroundAudioKeeper")
}
