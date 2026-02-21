import CoreData
import Foundation

enum ManagedObjectModelFactory {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [makeItemEntity(), makeSettingEntity()]
        return model
    }

    private static func makeItemEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Item"
        entity.managedObjectClassName = NSStringFromClass(ItemMO.self)

        var properties: [NSPropertyDescription] = []

        properties.append(attribute(name: "id", type: .UUIDAttributeType, isOptional: false, defaultValue: nil))
        properties.append(attribute(name: "deck", type: .stringAttributeType))
        properties.append(attribute(name: "rangeText", type: .stringAttributeType))
        properties.append(attribute(name: "page", type: .stringAttributeType, isOptional: true))
        properties.append(attribute(name: "profile", type: .integer16AttributeType))
        properties.append(attribute(name: "createdAt", type: .dateAttributeType))
        properties.append(attribute(name: "nextDueAt", type: .dateAttributeType))
        properties.append(attribute(name: "intervalIndex", type: .integer16AttributeType))
        properties.append(attribute(name: "historyData", type: .binaryDataAttributeType, isOptional: true))
        properties.append(attribute(name: "isArchived", type: .booleanAttributeType, defaultValue: false))

        entity.properties = properties
        entity.uniquenessConstraints = [["id"]]

        return entity
    }

    private static func makeSettingEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Setting"
        entity.managedObjectClassName = NSStringFromClass(SettingMO.self)

        var properties: [NSPropertyDescription] = []

        properties.append(attribute(name: "id", type: .UUIDAttributeType, isOptional: false, defaultValue: nil))
        properties.append(attribute(name: "dailyStartHour", type: .integer16AttributeType))
        properties.append(attribute(name: "dailyEndHour", type: .integer16AttributeType))
        properties.append(attribute(name: "dailyBatches", type: .integer16AttributeType))
        properties.append(attribute(name: "defaultProfile", type: .integer16AttributeType))
        properties.append(attribute(name: "badgeEnabled", type: .booleanAttributeType, defaultValue: true))
        properties.append(attribute(name: "batchTimesData", type: .binaryDataAttributeType, isOptional: true))

        entity.properties = properties
        entity.uniquenessConstraints = [["id"]]

        return entity
    }

    private static func attribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        attribute.defaultValue = defaultValue
        return attribute
    }
}
