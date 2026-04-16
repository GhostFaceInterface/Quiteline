import AVFoundation
import Foundation

public enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case m4a
    case caf
    case mp4

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .m4a:
            return "M4A Audio"
        case .caf:
            return "CAF PCM"
        case .mp4:
            return "MP4 Video"
        }
    }

    public var fileExtension: String {
        switch self {
        case .m4a:
            return "m4a"
        case .caf:
            return "caf"
        case .mp4:
            return "mp4"
        }
    }

    public var fileType: AVFileType {
        switch self {
        case .m4a:
            return .m4a
        case .caf:
            return .caf
        case .mp4:
            return .mp4
        }
    }

    public var presetName: String {
        switch self {
        case .m4a:
            return AVAssetExportPresetAppleM4A
        case .caf:
            return AVAssetExportPresetPassthrough
        case .mp4:
            return AVAssetExportPresetPassthrough
        }
    }

    public var isVideo: Bool {
        self == .mp4
    }
}

public struct ExportSettings: Codable, Equatable {
    public var fileName: String = "MergedAudio"
    public var format: ExportFormat = .m4a

    public init(fileName: String = "MergedAudio", format: ExportFormat = .m4a) {
        self.fileName = fileName
        self.format = format
    }

    public var suggestedFileName: String {
        let baseName = normalizedBaseName

        if baseName.lowercased().hasSuffix(".\(format.fileExtension)") {
            return baseName
        }

        return "\(baseName).\(format.fileExtension)"
    }

    private var normalizedBaseName: String {
        let trimmedName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmedName.isEmpty ? "MergedAudio" : trimmedName
        let existingExtension = (baseName as NSString).pathExtension.lowercased()
        let knownExportExtensions = Set(ExportFormat.allCases.map(\.fileExtension))

        if knownExportExtensions.contains(existingExtension) {
            return (baseName as NSString).deletingPathExtension
        }

        return baseName
    }

    public func resolvedURL(from pickedURL: URL) -> URL {
        if pickedURL.pathExtension.lowercased() == format.fileExtension {
            return pickedURL
        }

        return pickedURL.deletingPathExtension().appendingPathExtension(format.fileExtension)
    }
}
