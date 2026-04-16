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
    public var peakAmplitudeEstimate: Double
    public var waveformSamples: [Float]
    public var hasVideo: Bool
    public var videoWidth: Double
    public var videoHeight: Double

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
        peakAmplitudeEstimate: Double = 1,
        waveformSamples: [Float] = [],
        hasVideo: Bool = false,
        videoWidth: Double = 0,
        videoHeight: Double = 0
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
        self.peakAmplitudeEstimate = min(max(peakAmplitudeEstimate, 0.01), 1)
        self.waveformSamples = waveformSamples
        self.hasVideo = hasVideo
        self.videoWidth = max(videoWidth, 0)
        self.videoHeight = max(videoHeight, 0)
    }

    public var effectiveDuration: Double {
        max(trimEnd - trimStart, 0)
    }

    public var requestedMixGain: Double {
        let clampedVolume = min(max(volume, 0), 2)

        if clampedVolume >= 1 {
            let boostProgress = clampedVolume - 1
            return pow(10, (boostProgress * 18) / 20)
        }

        return pow(clampedVolume, 2.2)
    }

    public var maximumSafeGain: Double {
        min(0.98 / max(peakAmplitudeEstimate, 0.01), 8)
    }

    public var mixGain: Double {
        min(requestedMixGain, maximumSafeGain)
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

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case sourceURL
        case displayName
        case durationSeconds
        case trimStart
        case trimEnd
        case volume
        case fadeInDuration
        case fadeOutDuration
        case peakAmplitudeEstimate
        case waveformSamples
        case hasVideo
        case videoWidth
        case videoHeight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decodeIfPresent(MediaClipKind.self, forKey: .kind) ?? .media
        sourceURL = try container.decodeIfPresent(URL.self, forKey: .sourceURL)
        displayName = try container.decode(String.self, forKey: .displayName)
        durationSeconds = max(try container.decode(Double.self, forKey: .durationSeconds), 0)
        trimStart = max(try container.decodeIfPresent(Double.self, forKey: .trimStart) ?? 0, 0)
        trimEnd = min(
            try container.decodeIfPresent(Double.self, forKey: .trimEnd) ?? durationSeconds,
            durationSeconds
        )
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 1
        fadeInDuration = max(try container.decodeIfPresent(Double.self, forKey: .fadeInDuration) ?? 0, 0)
        fadeOutDuration = max(try container.decodeIfPresent(Double.self, forKey: .fadeOutDuration) ?? 0, 0)
        peakAmplitudeEstimate = min(
            max(try container.decodeIfPresent(Double.self, forKey: .peakAmplitudeEstimate) ?? 1, 0.01),
            1
        )
        waveformSamples = try container.decodeIfPresent([Float].self, forKey: .waveformSamples) ?? []
        hasVideo = try container.decodeIfPresent(Bool.self, forKey: .hasVideo) ?? false
        videoWidth = max(try container.decodeIfPresent(Double.self, forKey: .videoWidth) ?? 0, 0)
        videoHeight = max(try container.decodeIfPresent(Double.self, forKey: .videoHeight) ?? 0, 0)
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
            peakAmplitudeEstimate: peakAmplitudeEstimate,
            waveformSamples: waveformSamples ?? self.waveformSamples,
            hasVideo: hasVideo,
            videoWidth: videoWidth,
            videoHeight: videoHeight
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
            peakAmplitudeEstimate: 0.01,
            waveformSamples: Array(repeating: 0.04, count: 480)
        )
    }
}
