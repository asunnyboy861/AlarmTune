import Foundation
import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = PersistenceController.createManagedObjectModel()
        container = NSPersistentContainer(name: "AlarmTune", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("CoreData save failed: \(error.localizedDescription)")
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
            ("videoBackgroundName", .stringAttributeType, nil)  // M8.2 新增：视频背景标识
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
