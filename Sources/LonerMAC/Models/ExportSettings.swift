import AVFoundation
import Foundation

public enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case m4a
    case caf

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .m4a:
            return "M4A Audio"
        case .caf:
            return "CAF PCM"
        }
    }

    public var fileExtension: String {
        switch self {
        case .m4a:
            return "m4a"
        case .caf:
            return "caf"
        }
    }

    public var fileType: AVFileType {
        switch self {
        case .m4a:
            return .m4a
        case .caf:
            return .caf
        }
    }

    public var presetName: String {
        switch self {
        case .m4a:
            return AVAssetExportPresetAppleM4A
        case .caf:
            return AVAssetExportPresetPassthrough
        }
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
        let trimmedName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmedName.isEmpty ? "MergedAudio" : trimmedName

        if baseName.lowercased().hasSuffix(".\(format.fileExtension)") {
            return baseName
        }

        return "\(baseName).\(format.fileExtension)"
    }

    public func resolvedURL(from pickedURL: URL) -> URL {
        if pickedURL.pathExtension.lowercased() == format.fileExtension {
            return pickedURL
        }

        return pickedURL.deletingPathExtension().appendingPathExtension(format.fileExtension)
    }
}
