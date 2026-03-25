import AVFoundation
import Foundation

enum TimelineComposerError: LocalizedError {
    case noPlayableClips
    case noAudioTrack(URL)
    case exportSessionCreationFailed

    var errorDescription: String? {
        switch self {
        case .noPlayableClips:
            return "Onizleme veya export icin gecerli en az bir klip gerekli."
        case let .noAudioTrack(url):
            return "\(url.lastPathComponent) icin ses izi bulunamadi."
        case .exportSessionCreationFailed:
            return "Export oturumu olusturulamadi."
        }
    }
}

public struct TimelineComposer {
    private let timeScale: CMTimeScale = 600

    public init() {}

    @MainActor
    public func build(from clips: [MediaClip]) async throws -> TimelineBuildResult {
        let playableClips = clips.filter { $0.effectiveDuration > 0.05 }
        guard !playableClips.isEmpty else {
            throw TimelineComposerError.noPlayableClips
        }

        let composition = AVMutableComposition()
        guard let timelineTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw TimelineComposerError.noPlayableClips
        }

        let audioMix = AVMutableAudioMix()
        var inputParameters: [AVMutableAudioMixInputParameters] = []

        var cursor = CMTime.zero
        var offsets: [UUID: Double] = [:]

        for clip in playableClips {
            let duration = CMTime(seconds: clip.effectiveDuration, preferredTimescale: timeScale)
            let timelineRange = CMTimeRange(start: cursor, duration: duration)

            timelineTrack.insertEmptyTimeRange(timelineRange)
            offsets[clip.id] = cursor.seconds

            if clip.isSilence {
                cursor = CMTimeAdd(cursor, duration)
                continue
            }

            guard let sourceURL = clip.sourceURL else {
                throw TimelineComposerError.noPlayableClips
            }

            let asset = AVURLAsset(url: sourceURL)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)

            guard let sourceTrack = audioTracks.first else {
                throw TimelineComposerError.noAudioTrack(sourceURL)
            }

            guard let clipTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw TimelineComposerError.noPlayableClips
            }

            let start = CMTime(seconds: clip.trimStart, preferredTimescale: timeScale)
            let sourceRange = CMTimeRange(start: start, duration: duration)
            let gainLayers = decomposedGainLayers(for: clip.mixGain)

            try clipTrack.insertTimeRange(sourceRange, of: sourceTrack, at: cursor)

            let primaryParameters = AVMutableAudioMixInputParameters(track: clipTrack)
            applyVolumeEnvelope(for: clip, volume: gainLayers.first ?? 1, to: primaryParameters, at: cursor)
            inputParameters.append(primaryParameters)

            if gainLayers.count > 1 {
                for layerVolume in gainLayers.dropFirst() {
                    guard let boostTrack = composition.addMutableTrack(
                        withMediaType: .audio,
                        preferredTrackID: kCMPersistentTrackID_Invalid
                    ) else {
                        throw TimelineComposerError.noPlayableClips
                    }

                    try boostTrack.insertTimeRange(sourceRange, of: sourceTrack, at: cursor)
                    let boostParameters = AVMutableAudioMixInputParameters(track: boostTrack)
                    applyVolumeEnvelope(for: clip, volume: layerVolume, to: boostParameters, at: cursor)
                    inputParameters.append(boostParameters)
                }
            }
            cursor = CMTimeAdd(cursor, duration)
        }

        audioMix.inputParameters = inputParameters

        return TimelineBuildResult(
            composition: composition,
            audioMix: audioMix,
            clipOffsets: offsets,
            totalDuration: cursor.seconds
        )
    }

    private func applyVolumeEnvelope(
        for clip: MediaClip,
        volume: Float,
        to inputParameters: AVMutableAudioMixInputParameters,
        at cursor: CMTime
    ) {
        let clipDuration = clip.effectiveDuration
        let clipEnd = CMTimeAdd(cursor, CMTime(seconds: clipDuration, preferredTimescale: timeScale))
        let fades = clip.normalizedFadeDurations

        if fades.fadeIn > 0 {
            let fadeInDuration = CMTime(seconds: fades.fadeIn, preferredTimescale: timeScale)
            inputParameters.setVolume(0, at: cursor)
            inputParameters.setVolumeRamp(
                fromStartVolume: 0,
                toEndVolume: volume,
                timeRange: CMTimeRange(start: cursor, duration: fadeInDuration)
            )
        } else {
            inputParameters.setVolume(volume, at: cursor)
        }

        if fades.fadeOut > 0 {
            let fadeOutStartSeconds = max(clipDuration - fades.fadeOut, 0)
            let fadeOutStart = CMTimeAdd(
                cursor,
                CMTime(seconds: fadeOutStartSeconds, preferredTimescale: timeScale)
            )
            let fadeOutDuration = CMTime(seconds: fades.fadeOut, preferredTimescale: timeScale)

            inputParameters.setVolume(volume, at: fadeOutStart)
            inputParameters.setVolumeRamp(
                fromStartVolume: volume,
                toEndVolume: 0,
                timeRange: CMTimeRange(start: fadeOutStart, duration: fadeOutDuration)
            )
            inputParameters.setVolume(0, at: clipEnd)
        } else {
            inputParameters.setVolume(volume, at: clipEnd)
        }
    }

    private func decomposedGainLayers(for volume: Double) -> [Float] {
        var remaining = min(max(volume, 0), 16)
        var layers: [Float] = []

        while remaining > 0.0001 {
            let layerVolume = Float(min(remaining, 1))
            layers.append(layerVolume)
            remaining -= Double(layerVolume)
        }

        return layers.isEmpty ? [0] : layers
    }
}
