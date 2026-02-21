import CoreData
import Foundation

@objc(ItemMO)
final class ItemMO: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var deck: String
    @NSManaged var rangeText: String
    @NSManaged var page: String?
    @NSManaged var profile: Int16
    @NSManaged var createdAt: Date
    @NSManaged var nextDueAt: Date
    @NSManaged var intervalIndex: Int16
    @NSManaged var historyData: Data?
    @NSManaged var isArchived: Bool
}

extension ItemMO {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ItemMO> {
        NSFetchRequest<ItemMO>(entityName: "Item")
    }
}
