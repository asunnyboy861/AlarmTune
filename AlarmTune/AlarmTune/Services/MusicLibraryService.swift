import Foundation
import MediaPlayer

/// 封装 Apple Music / iTunes 音乐库交互
/// 单例模式，与 AudioService/VolumeManager 等保持一致
final class MusicLibraryService: ObservableObject {
    static let shared = MusicLibraryService()

    @Published var authorized: Bool = false

    private let cacheKey = "appleMusicCache"

    private init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        let status = MPMediaLibrary.authorizationStatus()
        authorized = (status == .authorized)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorized = (status == .authorized)
                completion(self.authorized)
            }
        }
    }

    /// 保存选中的音乐库歌曲信息
    /// - Returns: "appleMusic:{persistentID}" 格式的标识符，存入 AlarmItem.soundName
    func saveSelectedSong(_ item: MPMediaItem) -> String {
        let identifier = "appleMusic:\(item.persistentID)"
        cacheSongMetadata(item)
        return identifier
    }

    /// 从 persistentID 查询歌曲信息
    func song(for persistentID: UInt64) -> MPMediaItem? {
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: NSNumber(value: persistentID),
            forProperty: MPMediaItemPropertyPersistentID
        ))
        return query.items?.first
    }

    /// 获取缓存的显示名（无需查询音乐库）
    func displayName(for identifier: String) -> String? {
        guard identifier.hasPrefix("appleMusic:") else { return nil }
        let cache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: String] ?? [:]
        return cache[identifier]
    }

    /// 返回所有已缓存的音乐库歌曲 (identifier, displayName)
    func cachedSongs() -> [(key: String, name: String)] {
        let cache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: String] ?? [:]
        return cache.sorted { $0.key < $1.key }.map { (key: $0.key, name: $0.value) }
    }

    private func cacheSongMetadata(_ item: MPMediaItem) {
        let key = "appleMusic:\(item.persistentID)"
        var cache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: String] ?? [:]
        let title = item.title ?? "Unknown"
        let artist = item.artist ?? ""
        cache[key] = artist.isEmpty ? title : "\(title) - \(artist)"
        UserDefaults.standard.set(cache, forKey: cacheKey)
    }
}
