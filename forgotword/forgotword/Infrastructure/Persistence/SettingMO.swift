import CoreData
import Foundation

@objc(SettingMO)
final class SettingMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var dailyStartHour: Int16
    @NSManaged var dailyEndHour: Int16
    @NSManaged var dailyBatches: Int16
    @NSManaged var defaultProfile: Int16
    @NSManaged var badgeEnabled: Bool
    @NSManaged var batchTimesData: Data?
}

extension SettingMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SettingMO> {
        NSFetchRequest<SettingMO>(entityName: "Setting")
    }
}
