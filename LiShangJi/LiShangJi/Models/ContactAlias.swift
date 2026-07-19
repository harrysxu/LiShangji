import Foundation
import SwiftData

@Model
final class ContactAlias {
    var id: UUID = UUID()
    var name: String = ""
    var normalizedName: String = ""
    var createdAt: Date = Date()
    var contact: Contact?

    init(name: String, contact: Contact? = nil) {
        self.id = UUID()
        self.name = name
        self.normalizedName = Contact.normalize(name)
        self.createdAt = Date()
        self.contact = contact
    }
}
