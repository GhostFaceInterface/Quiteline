import Foundation

public enum MediaClipKind: String, Codable {
    case media
    case silence
}

public struct MediaClip: Identifiable, Equatable, Codable {
    public let id: UUID
    public let kind: MediaClipKind
    public let sourceURL: URL?
    public let displayName: String
    public let durationSeconds: Double
    public var trimStart: Double
    public var trimEnd: Double
    public var volume: Double
    public var fadeInDuration: Double
    public var fadeOutDuration: Double
    public var waveformSamples: [Float]

    public init(
        id: UUID = UUID(),
        kind: MediaClipKind = .media,
        sourceURL: URL?,
        displayName: String,
        durationSeconds: Double,
        trimStart: Double = 0,
        trimEnd: Double? = nil,
        volume: Double = 1,
        fadeInDuration: Double = 0,
        fadeOutDuration: Double = 0,
        waveformSamples: [Float] = []
    ) {
        self.id = id
        self.kind = kind
        self.sourceURL = sourceURL
        self.displayName = displayName
        self.durationSeconds = max(durationSeconds, 0)
        self.trimStart = max(trimStart, 0)
        self.trimEnd = min(trimEnd ?? durationSeconds, durationSeconds)
        self.volume = volume
        self.fadeInDuration = max(fadeInDuration, 0)
        self.fadeOutDuration = max(fadeOutDuration, 0)
        self.waveformSamples = waveformSamples
    }

    public var effectiveDuration: Double {
        max(trimEnd - trimStart, 0)
    }

    public var mixGain: Double {
        let clampedVolume = min(max(volume, 0), 2)

        if clampedVolume >= 1 {
            let boostProgress = clampedVolume - 1
            return pow(10, (boostProgress * 24) / 20)
        }

        return pow(clampedVolume, 2.2)
    }

    public var normalizedFadeDurations: (fadeIn: Double, fadeOut: Double) {
        let duration = effectiveDuration
        guard duration > 0 else {
            return (0, 0)
        }

        var fadeIn = min(fadeInDuration, duration)
        var fadeOut = min(fadeOutDuration, duration)

        if fadeIn + fadeOut > duration {
            let scale = duration / (fadeIn + fadeOut)
            fadeIn *= scale
            fadeOut *= scale
        }

        return (fadeIn, fadeOut)
    }

    public var isSilence: Bool {
        kind == .silence
    }

    public func duplicated(
        id: UUID = UUID(),
        trimStart: Double? = nil,
        trimEnd: Double? = nil,
        volume: Double? = nil,
        fadeInDuration: Double? = nil,
        fadeOutDuration: Double? = nil,
        waveformSamples: [Float]? = nil
    ) -> MediaClip {
        MediaClip(
            id: id,
            kind: kind,
            sourceURL: sourceURL,
            displayName: displayName,
            durationSeconds: durationSeconds,
            trimStart: trimStart ?? self.trimStart,
            trimEnd: trimEnd ?? self.trimEnd,
            volume: volume ?? self.volume,
            fadeInDuration: fadeInDuration ?? self.fadeInDuration,
            fadeOutDuration: fadeOutDuration ?? self.fadeOutDuration,
            waveformSamples: waveformSamples ?? self.waveformSamples
        )
    }

    public static func silence(durationSeconds: Double) -> MediaClip {
        let clampedDuration = max(durationSeconds, 0.25)

        return MediaClip(
            kind: .silence,
            sourceURL: nil,
            displayName: "Silence",
            durationSeconds: clampedDuration,
            trimEnd: clampedDuration,
            waveformSamples: Array(repeating: 0.04, count: 480)
        )
    }
}
