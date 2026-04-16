import Foundation

public struct SavedProject: Codable {
    public var version: Int = 1
    public var clips: [MediaClip]
    public var exportSettings: ExportSettings

    public init(version: Int = 1, clips: [MediaClip], exportSettings: ExportSettings) {
        self.version = version
        self.clips = clips
        self.exportSettings = exportSettings
    }
}
