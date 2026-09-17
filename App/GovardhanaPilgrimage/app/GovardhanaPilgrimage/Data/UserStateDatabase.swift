import Foundation
import GRDB

struct UserStateDatabase {
    let writer: DatabaseQueue
    let url: URL

    init(url: URL) throws {
        var configuration = Configuration()
        configuration.label = "GovardhanaPilgrimage.UserState"
        writer = try DatabaseQueue(path: url.path, configuration: configuration)
        self.url = url
        try migrate()
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1-foundation") { database in
            try database.create(table: "bookmarks") { table in
                table.column("id", .text).primaryKey()
                table.column("target_type", .text).notNull()
                table.column("target_id", .text).notNull()
                table.column("created_at", .datetime).notNull()
            }
            try database.create(table: "reading_positions") { table in
                table.column("target_type", .text).notNull()
                table.column("target_id", .text).notNull()
                table.column("position_id", .text).notNull()
                table.column("updated_at", .datetime).notNull()
                table.primaryKey(["target_type", "target_id"])
            }
            try database.create(table: "settings") { table in
                table.column("key", .text).primaryKey()
                table.column("value", .text).notNull()
            }
        }
        migrator.registerMigration("v2-semantic-story-position") { database in
            try database.alter(table: "reading_positions") { table in
                table.add(column: "section_id", .text)
                table.add(column: "block_id", .text)
            }
        }
        migrator.registerMigration("v3-semantic-bookmarks") { database in
            try database.alter(table: "bookmarks") { table in
                table.add(column: "story_id", .text)
                table.add(column: "section_id", .text)
            }
            try database.create(
                index: "bookmarks_unique_target",
                on: "bookmarks",
                columns: ["target_type", "target_id"],
                unique: true
            )
        }
        migrator.registerMigration("v4-vedabase-bookmarks") { database in
            try database.create(table: "vedabase_bookmarks") { table in
                table.column("url", .text).primaryKey()
                table.column("title", .text).notNull()
                table.column("created_at", .datetime).notNull()
            }
        }
        migrator.registerMigration("v5-person-bookmarks") { database in
            try database.alter(table: "bookmarks") { table in
                table.add(column: "person_id", .text)
            }
        }
        try migrator.migrate(writer)
    }

    func setSetting(key: String, value: String) throws {
        try writer.write { database in
            try database.execute(
                sql: "INSERT INTO settings(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                arguments: [key, value]
            )
        }
    }

    func setting(key: String) throws -> String? {
        try writer.read { database in
            try String.fetchOne(database, sql: "SELECT value FROM settings WHERE key = ?", arguments: [key])
        }
    }

    func saveStoryPosition(_ position: StoryReadingPosition) throws {
        try writer.write { database in
            try database.execute(
                sql: """
                    INSERT INTO reading_positions(target_type, target_id, position_id, section_id, block_id, updated_at)
                    VALUES ('story', ?, ?, ?, ?, ?)
                    ON CONFLICT(target_type, target_id) DO UPDATE SET
                        position_id = excluded.position_id,
                        section_id = excluded.section_id,
                        block_id = excluded.block_id,
                        updated_at = excluded.updated_at
                    """,
                arguments: [
                    position.storyID.rawValue,
                    position.blockID.rawValue,
                    position.sectionID.rawValue,
                    position.blockID.rawValue,
                    Date(),
                ]
            )
        }
    }

    func storyPosition(storyID: StoryID) throws -> StoryReadingPosition? {
        try writer.read { database in
            guard let row = try Row.fetchOne(
                database,
                sql: "SELECT section_id, block_id FROM reading_positions WHERE target_type = 'story' AND target_id = ?",
                arguments: [storyID.rawValue]
            ), let sectionID: String = row["section_id"], let blockID: String = row["block_id"] else {
                return nil
            }
            return StoryReadingPosition(
                storyID: storyID,
                sectionID: StorySectionID(rawValue: sectionID),
                blockID: StoryBlockID(rawValue: blockID)
            )
        }
    }

    func saveWorkPosition(_ position: WorkReadingPosition) throws {
        try writer.write { database in
            try database.execute(
                sql: """
                    INSERT INTO reading_positions(target_type, target_id, position_id, updated_at)
                    VALUES ('source_work', ?, ?, ?)
                    ON CONFLICT(target_type, target_id) DO UPDATE SET
                        position_id = excluded.position_id,
                        section_id = NULL,
                        block_id = NULL,
                        updated_at = excluded.updated_at
                    """,
                arguments: [position.workID.rawValue, position.passageID.rawValue, Date()]
            )
        }
    }

    func workPosition(workID: SourceWorkID) throws -> WorkReadingPosition? {
        try writer.read { database in
            guard let passageID = try String.fetchOne(
                database,
                sql: "SELECT position_id FROM reading_positions WHERE target_type = 'source_work' AND target_id = ?",
                arguments: [workID.rawValue]
            ) else {
                return nil
            }
            return WorkReadingPosition(workID: workID, passageID: SourcePassageID(rawValue: passageID))
        }
    }

    func savePersonPosition(_ position: PersonReadingPosition) throws {
        try writer.write { database in
            try database.execute(sql: """
                INSERT INTO reading_positions(target_type, target_id, position_id, section_id, block_id, updated_at)
                VALUES ('person', ?, ?, ?, ?, ?)
                ON CONFLICT(target_type, target_id) DO UPDATE SET
                    position_id = excluded.position_id,
                    section_id = excluded.section_id,
                    block_id = excluded.block_id,
                    updated_at = excluded.updated_at
                """, arguments: [position.personID.rawValue, position.blockID.rawValue,
                                   position.sectionID.rawValue, position.blockID.rawValue, Date()])
        }
    }

    func personPosition(personID: PersonID) throws -> PersonReadingPosition? {
        try writer.read { database in
            guard let row = try Row.fetchOne(database, sql: """
                SELECT section_id, block_id FROM reading_positions WHERE target_type = 'person' AND target_id = ?
                """, arguments: [personID.rawValue]),
                  let sectionID: String = row["section_id"], let blockID: String = row["block_id"] else { return nil }
            return PersonReadingPosition(personID: personID, sectionID: PersonSectionID(rawValue: sectionID),
                                         blockID: PersonBlockID(rawValue: blockID))
        }
    }

    func saveBookmark(_ target: BookmarkTarget) throws {
        let values = bookmarkValues(for: target)
        try writer.write { database in
            try database.execute(
                sql: """
                    INSERT INTO bookmarks(id, target_type, target_id, story_id, person_id, section_id, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(target_type, target_id) DO NOTHING
                    """,
                arguments: [values.id, values.type, values.targetID, values.storyID, values.personID, values.sectionID, Date()]
            )
        }
    }

    func removeBookmark(_ target: BookmarkTarget) throws {
        let values = bookmarkValues(for: target)
        try writer.write { database in
            try database.execute(
                sql: "DELETE FROM bookmarks WHERE target_type = ? AND target_id = ?",
                arguments: [values.type, values.targetID]
            )
        }
    }

    func bookmarks() throws -> [BookmarkRecord] {
        try writer.read { database in
            try Row.fetchAll(
                database,
                sql: "SELECT id, target_type, target_id, story_id, person_id, section_id, created_at FROM bookmarks ORDER BY created_at DESC"
            ).compactMap { row in
                let id: String = row["id"]
                let type: String = row["target_type"]
                let targetID: String = row["target_id"]
                let createdAt: Date = row["created_at"]
                switch type {
                case "story":
                    guard let storyID: String = row["story_id"], let sectionID: String = row["section_id"] else {
                        return nil
                    }
                    return BookmarkRecord(
                        id: id,
                        target: .story(
                            StoryReadingPosition(
                                storyID: StoryID(rawValue: storyID),
                                sectionID: StorySectionID(rawValue: sectionID),
                                blockID: StoryBlockID(rawValue: targetID)
                            )
                        ),
                        createdAt: createdAt
                    )
                case "source_passage":
                    return BookmarkRecord(
                        id: id,
                        target: .source(SourcePassageID(rawValue: targetID)),
                        createdAt: createdAt
                    )
                case "person":
                    guard let personID: String = row["person_id"], let sectionID: String = row["section_id"] else {
                        return nil
                    }
                    return BookmarkRecord(id: id,
                                          target: .person(PersonReadingPosition(
                                            personID: PersonID(rawValue: personID),
                                            sectionID: PersonSectionID(rawValue: sectionID),
                                            blockID: PersonBlockID(rawValue: targetID))),
                                          createdAt: createdAt)
                default:
                    return nil
                }
            }
        }
    }

    func saveVedabaseBookmark(url: URL, title: String) throws {
        guard VedabaseBookmarkRecord.isBookmarkable(url) else {
            throw VedabaseBookmarkError.invalidURL
        }
        let displayTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        try writer.write { database in
            try database.execute(
                sql: "INSERT INTO vedabase_bookmarks(url, title, created_at) VALUES (?, ?, ?) ON CONFLICT(url) DO UPDATE SET title = excluded.title",
                arguments: [url.absoluteString, displayTitle.isEmpty ? "Vedabase reading" : displayTitle, Date()]
            )
        }
    }

    func removeVedabaseBookmark(url: URL) throws {
        try writer.write { database in
            try database.execute(sql: "DELETE FROM vedabase_bookmarks WHERE url = ?", arguments: [url.absoluteString])
        }
    }

    func vedabaseBookmarks() throws -> [VedabaseBookmarkRecord] {
        try writer.read { database in
            try Row.fetchAll(
                database,
                sql: "SELECT url, title, created_at FROM vedabase_bookmarks ORDER BY created_at DESC"
            ).compactMap { row in
                let urlString: String = row["url"]
                guard let url = URL(string: urlString), VedabaseBookmarkRecord.isBookmarkable(url) else { return nil }
                return VedabaseBookmarkRecord(url: url, title: row["title"], createdAt: row["created_at"])
            }
        }
    }

    private func bookmarkValues(
        for target: BookmarkTarget
    ) -> (id: String, type: String, targetID: String, storyID: String?, personID: String?, sectionID: String?) {
        switch target {
        case let .story(position):
            return (
                "story:\(position.blockID.rawValue)",
                "story",
                position.blockID.rawValue,
                position.storyID.rawValue,
                nil,
                position.sectionID.rawValue
            )
        case let .source(passageID):
            return ("source:\(passageID.rawValue)", "source_passage", passageID.rawValue, nil, nil, nil)
        case let .person(position):
            return ("person:\(position.blockID.rawValue)", "person", position.blockID.rawValue,
                    nil, position.personID.rawValue, position.sectionID.rawValue)
        }
    }
}

enum VedabaseBookmarkError: LocalizedError {
    case invalidURL

    var errorDescription: String? { "Only Vedabase library pages can be bookmarked." }
}
