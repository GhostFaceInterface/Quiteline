import Foundation

public struct ProjectPersistenceService {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    public init() {}

    public func save(project: SavedProject, to url: URL) throws {
        let data = try encoder.encode(project)
        try data.write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws -> SavedProject {
        let data = try Data(contentsOf: url)
        return try decoder.decode(SavedProject.self, from: data)
    }
}
