import Foundation

struct AppContainer {
    let contentDatabase: ContentDatabase
    let userStateDatabase: UserStateDatabase
    let contentRepository: any ContentRepository

    static func live(
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) throws -> AppContainer {
        guard let contentURL = bundle.url(forResource: "radhakunda-content", withExtension: "sqlite") else {
            throw AppInitializationError.missingBundledContentDatabase
        }
        let contentDatabase = try ContentDatabase(url: contentURL)
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = applicationSupport.appending(path: "GovardhanaPilgrimage", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        let userStateDatabase = try UserStateDatabase(url: appDirectory.appending(path: "user-state.sqlite"))
        return AppContainer(
            contentDatabase: contentDatabase,
            userStateDatabase: userStateDatabase,
            contentRepository: SQLiteContentRepository(database: contentDatabase)
        )
    }
}

enum AppInitializationError: LocalizedError {
    case missingBundledContentDatabase

    var errorDescription: String? {
        switch self {
        case .missingBundledContentDatabase:
            "The bundled fixture content database is missing."
        }
    }
}

