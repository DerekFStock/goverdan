import Foundation
import GRDB

struct ContentDatabase {
    let reader: DatabaseQueue
    let url: URL

    init(url: URL) throws {
        var configuration = Configuration()
        configuration.readonly = true
        configuration.label = "GovardhanaPilgrimage.Content"
        reader = try DatabaseQueue(path: url.path, configuration: configuration)
        self.url = url
        try reader.read { database in
            guard try String.fetchOne(database, sql: "PRAGMA integrity_check") == "ok" else {
                throw DatabaseError(message: "Bundled content database failed integrity validation")
            }
        }
    }
}

