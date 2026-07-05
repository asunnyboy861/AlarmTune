import Foundation
import CoreData
import os.log

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = PersistenceController.createManagedObjectModel()
        container = NSPersistentContainer(name: "AlarmTune", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                // M8 修复：fatalError 改为优雅降级（之前数据库损坏时 App 启动即崩溃）
                AppLogger.persistence.error("Failed to load persistent store: \(error.localizedDescription, privacy: .public)")
                self?.recoverFromStoreCorruption()
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// M8 新增：从存储损坏中恢复 — 删除损坏的存储文件并重建空存储
    /// 用户会丢失闹钟数据，但 App 仍可启动使用（优于崩溃无法打开）
    private func recoverFromStoreCorruption() {
        guard let storeDescription = container.persistentStoreDescriptions.first,
              let storeURL = storeDescription.url else {
            AppLogger.persistence.error("No store URL found for recovery")
            return
        }

        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(
                at: storeURL,
                ofType: NSSQLiteStoreType
            )
            AppLogger.persistence.info("Corrupted store deleted, attempting reload")

            container.loadPersistentStores { _, error in
                if let error = error {
                    AppLogger.persistence.error("Reload failed: \(error.localizedDescription, privacy: .public). App will run with empty store.")
                } else {
                    AppLogger.persistence.info("Store reloaded successfully")
                }
            }
        } catch {
            AppLogger.persistence.error("Recovery failed: \(error.localizedDescription, privacy: .public). App will run with empty store.")
        }
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            AppLogger.persistence.error("CoreData save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let alarmEntity = NSEntityDescription()
        alarmEntity.name = "AlarmItem"
        alarmEntity.managedObjectClassName = "AlarmItem"

        let attributes: [(String, NSAttributeType, Any?)] = [
            ("id", .stringAttributeType, nil),
            ("label", .stringAttributeType, "Alarm"),
            ("hour", .integer16AttributeType, 7),
            ("minute", .integer16AttributeType, 0),
            ("volume", .floatAttributeType, 0.55),
            ("soundName", .stringAttributeType, "Gentle Morning"),
            ("isFadeIn", .booleanAttributeType, false),
            ("fadeInDuration", .doubleAttributeType, 5.0),
            ("isVibrate", .booleanAttributeType, true),
            ("isEnabled", .booleanAttributeType, true),
            ("isSnoozeEnabled", .booleanAttributeType, true),
            ("snoozeDuration", .integer16AttributeType, 5),
            ("category", .stringAttributeType, nil),
            ("repeatDays", .transformableAttributeType, nil),
            ("createdAt", .dateAttributeType, nil),
            ("videoBackgroundName", .stringAttributeType, nil),  // M8.2 新增：视频背景标识
            ("videoVolume", .floatAttributeType, 0.0),  // V3 新增：视频音量，默认 0（静音，向后兼容）
            ("audioSource", .stringAttributeType, "alarmSound")  // W1 新增：音频来源，默认闹钟铃声（向后兼容）
        ]

        var propertyDescriptions: [NSPropertyDescription] = []

        for (name, type, defaultValue) in attributes {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            // id, createdAt, category, repeatDays, videoBackgroundName have no default value but are optional in the model
            let optionalAttributes: Set<String> = ["id", "createdAt", "category", "repeatDays", "videoBackgroundName"]
            attr.isOptional = optionalAttributes.contains(name) || defaultValue != nil
            if let defaultValue = defaultValue {
                attr.defaultValue = defaultValue
            }
            if name == "repeatDays" {
                attr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue
            }
            propertyDescriptions.append(attr)
        }

        alarmEntity.properties = propertyDescriptions
        model.entities = [alarmEntity]

        return model
    }
}
