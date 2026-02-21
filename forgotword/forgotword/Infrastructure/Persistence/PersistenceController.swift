import CoreData
import Foundation

/// Wraps Core Data stack configuration.
final class PersistenceController {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(model: NSManagedObjectModel, inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ForgotwordModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
    }

    static func makeInMemory(model: NSManagedObjectModel) -> PersistenceController {
        PersistenceController(model: model, inMemory: true)
    }

    func seedDefaultsIfNeeded() {
        let context = viewContext
        context.performAndWait {
            let request = SettingMO.fetchRequest()
            request.fetchLimit = 1
            if let existing = try? context.fetch(request), !existing.isEmpty {
                return
            }

            let setting = SettingMO(context: context)
            setting.id = UUID()
            setting.dailyStartHour = Int16(UserSettings.default.notificationWindow.startHour)
            setting.dailyEndHour = Int16(UserSettings.default.notificationWindow.endHour)
            setting.dailyBatches = Int16(UserSettings.default.notificationWindow.dailyBatches)
            setting.defaultProfile = Int16(UserSettings.default.defaultProfile.rawValue)
            setting.badgeEnabled = UserSettings.default.badgeEnabled
            setting.batchTimesData = try? JSONEncoder().encode(
                UserSettings.default.notificationWindow.batchTimes.map(BatchTimeDTO.init)
            )

            try? context.save()
        }
    }
}
