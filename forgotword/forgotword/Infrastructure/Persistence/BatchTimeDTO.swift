import Foundation

struct BatchTimeDTO: Codable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(from components: DateComponents) {
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }

    var dateComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
}
