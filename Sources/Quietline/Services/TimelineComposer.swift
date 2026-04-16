import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

enum TimelineComposerError: LocalizedError {
    case noPlayableClips
    case noAudioTrack(URL)
    case exportSessionCreationFailed
    case videoTrackCreationFailed

    var errorDescription: String? {
        switch self {
        case .noPlayableClips:
            return "Onizleme veya export icin gecerli en az bir klip gerekli."
        case let .noAudioTrack(url):
            return "\(url.lastPathComponent) icin ses izi bulunamadi."
        case .exportSessionCreationFailed:
            return "Export oturumu olusturulamadi."
        case .videoTrackCreationFailed:
            return "Video export icin gerekli gecici video izi olusturulamadi."
        }
    }
}

public struct TimelineComposer {
    private let timeScale: CMTimeScale = 600
    private let blackVideoWidth = 160
    private let blackVideoHeight = 90
    private let blackVideoAverageBitRate = 24_000
    private let defaultVideoRenderSize = CGSize(width: 960, height: 540)
    private let maximumVideoRenderDimension: CGFloat = 960

    public init() {}

    @MainActor
    public func build(from clips: [MediaClip], includeVideo: Bool = false) async throws -> TimelineBuildResult {
        let playableClips = clips.filter { $0.effectiveDuration > 0.05 }
        guard !playableClips.isEmpty else {
            throw TimelineComposerError.noPlayableClips
        }

        let shouldUsePassthroughAudio = includeVideo && playableClips.allSatisfy { clip in
            let fades = clip.normalizedFadeDurations
            return abs(clip.volume - 1) < 0.0001
                && fades.fadeIn <= 0.0001
                && fades.fadeOut <= 0.0001
        }
        let composition = AVMutableComposition()
        let timelineTrack: AVMutableCompositionTrack?
        let passthroughAudioTrack: AVMutableCompositionTrack?

        if shouldUsePassthroughAudio {
            timelineTrack = nil
            guard let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw TimelineComposerError.noPlayableClips
            }
            passthroughAudioTrack = audioTrack
        } else {
            guard let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw TimelineComposerError.noPlayableClips
            }
            timelineTrack = audioTrack
            passthroughAudioTrack = nil
        }
        let audioMix = AVMutableAudioMix()
        var inputParameters: [AVMutableAudioMixInputParameters] = []
        let totalDuration = playableClips.reduce(0) { $0 + $1.effectiveDuration }
        let hasSourceVideo = includeVideo
            ? try await containsSourceVideo(in: playableClips)
            : false
        let blackVideoSource = includeVideo && !hasSourceVideo
            ? try await makeBlackVideoSource(durationSeconds: totalDuration)
            : nil

        var cursor = CMTime.zero
        var offsets: [UUID: Double] = [:]
        var videoOutputTrack: AVMutableCompositionTrack?
        var hasAppliedVideoTransform = false
        var firstVideoNaturalSize: CGSize?
        var firstVideoPreferredTransform: CGAffineTransform?

        for clip in playableClips {
            let duration = CMTime(seconds: clip.effectiveDuration, preferredTimescale: timeScale)
            let timelineRange = CMTimeRange(start: cursor, duration: duration)

            timelineTrack?.insertEmptyTimeRange(timelineRange)
            offsets[clip.id] = cursor.seconds

            if clip.isSilence {
                passthroughAudioTrack?.insertEmptyTimeRange(timelineRange)

                if includeVideo {
                    let videoTrack = try passthroughVideoTrack(
                        in: composition,
                        currentTrack: &videoOutputTrack
                    )
                    try insertVideoGap(
                        blackVideoSource,
                        duration: duration,
                        range: timelineRange,
                        at: cursor,
                        into: videoTrack
                    )
                }

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

            let start = CMTime(seconds: clip.trimStart, preferredTimescale: timeScale)
            let sourceRange = CMTimeRange(start: start, duration: duration)
            let gainLayers = decomposedGainLayers(for: clip.mixGain)

            if let passthroughAudioTrack {
                try passthroughAudioTrack.insertTimeRange(sourceRange, of: sourceTrack, at: cursor)
            } else {
                guard let clipTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    throw TimelineComposerError.noPlayableClips
                }

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
            }

            if includeVideo {
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                let videoTrack = try passthroughVideoTrack(
                    in: composition,
                    currentTrack: &videoOutputTrack
                )

                if let sourceVideoTrack = videoTracks.first {
                    try videoTrack.insertTimeRange(sourceRange, of: sourceVideoTrack, at: cursor)

                    let sourceNaturalSize = try await sourceVideoTrack.load(.naturalSize)
                    let sourcePreferredTransform = try await sourceVideoTrack.load(.preferredTransform)
                    if firstVideoNaturalSize == nil {
                        firstVideoNaturalSize = sourceNaturalSize
                        firstVideoPreferredTransform = sourcePreferredTransform
                    }

                    if !hasAppliedVideoTransform {
                        videoTrack.preferredTransform = sourcePreferredTransform
                        hasAppliedVideoTransform = true
                    }
                } else {
                    try insertVideoGap(
                        blackVideoSource,
                        duration: duration,
                        range: timelineRange,
                        at: cursor,
                        into: videoTrack
                    )
                }
            }

            cursor = CMTimeAdd(cursor, duration)
        }

        audioMix.inputParameters = inputParameters
        let fallbackVideoComposition = makeFallbackVideoComposition(
            track: videoOutputTrack,
            duration: cursor,
            naturalSize: firstVideoNaturalSize,
            preferredTransform: firstVideoPreferredTransform
        )

        return TimelineBuildResult(
            composition: composition,
            audioMix: audioMix,
            videoComposition: fallbackVideoComposition,
            clipOffsets: offsets,
            totalDuration: cursor.seconds,
            temporaryURLs: blackVideoSource.map { [$0.url] } ?? []
        )
    }

    private func passthroughVideoTrack(
        in composition: AVMutableComposition,
        currentTrack: inout AVMutableCompositionTrack?
    ) throws -> AVMutableCompositionTrack {
        if let currentTrack {
            return currentTrack
        }

        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw TimelineComposerError.videoTrackCreationFailed
        }

        currentTrack = videoTrack
        return videoTrack
    }

    @MainActor
    private func containsSourceVideo(in clips: [MediaClip]) async throws -> Bool {
        for clip in clips {
            guard !clip.isSilence,
                  let sourceURL = clip.sourceURL else {
                continue
            }

            let asset = AVURLAsset(url: sourceURL)
            if try await !asset.loadTracks(withMediaType: .video).isEmpty {
                return true
            }
        }

        return false
    }

    @MainActor
    private func makeBlackVideoSource(durationSeconds: Double) async throws -> (track: AVAssetTrack, url: URL) {
        let width = blackVideoWidth
        let height = blackVideoHeight
        let averageBitRate = blackVideoAverageBitRate
        let blackVideoURL = try await Task.detached(priority: .utility) {
            try Self.makeBlackVideoFile(
                durationSeconds: durationSeconds,
                width: width,
                height: height,
                averageBitRate: averageBitRate
            )
        }.value
        let blackAsset = AVURLAsset(url: blackVideoURL)
        let blackTracks = try await blackAsset.loadTracks(withMediaType: .video)

        guard let blackSourceTrack = blackTracks.first else {
            throw TimelineComposerError.videoTrackCreationFailed
        }

        return (blackSourceTrack, blackVideoURL)
    }

    private func makeFallbackVideoComposition(
        track: AVMutableCompositionTrack?,
        duration: CMTime,
        naturalSize: CGSize?,
        preferredTransform: CGAffineTransform?
    ) -> AVMutableVideoComposition? {
        guard let track, CMTimeCompare(duration, .zero) > 0 else {
            return nil
        }

        let renderSize: CGSize
        let transform: CGAffineTransform

        if let naturalSize,
           let preferredTransform {
            let orientedSize = orientedSize(naturalSize: naturalSize, preferredTransform: preferredTransform)
            renderSize = cappedEvenRenderSize(for: orientedSize)
            transform = fittedTransform(
                naturalSize: naturalSize,
                preferredTransform: preferredTransform,
                renderSize: renderSize
            )
        } else {
            renderSize = defaultVideoRenderSize
            transform = .identity
        }

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        layerInstruction.setTransform(transform, at: .zero)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        instruction.backgroundColor = CGColor.black
        instruction.layerInstructions = [layerInstruction]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]
        return videoComposition
    }

    private func orientedSize(naturalSize: CGSize, preferredTransform: CGAffineTransform) -> CGSize {
        let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        return CGSize(width: abs(transformedRect.width), height: abs(transformedRect.height))
    }

    private func cappedEvenRenderSize(for size: CGSize) -> CGSize {
        let largestDimension = max(size.width, size.height)
        let scale = largestDimension > maximumVideoRenderDimension
            ? maximumVideoRenderDimension / largestDimension
            : 1

        return CGSize(
            width: evenVideoDimension(size.width * scale),
            height: evenVideoDimension(size.height * scale)
        )
    }

    private func evenVideoDimension(_ value: CGFloat) -> CGFloat {
        let floored = max(Int(value.rounded(.down)), 2)
        let evenValue = floored.isMultiple(of: 2) ? floored : floored - 1
        return CGFloat(max(evenValue, 2))
    }

    private func fittedTransform(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        renderSize: CGSize
    ) -> CGAffineTransform {
        let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let orientedSize = CGSize(width: abs(transformedRect.width), height: abs(transformedRect.height))

        guard orientedSize.width > 0, orientedSize.height > 0 else {
            return preferredTransform
        }

        let scale = min(renderSize.width / orientedSize.width, renderSize.height / orientedSize.height)
        let xOffset = (renderSize.width - orientedSize.width * scale) / 2
        let yOffset = (renderSize.height - orientedSize.height * scale) / 2

        return preferredTransform
            .concatenating(CGAffineTransform(translationX: -transformedRect.minX, y: -transformedRect.minY))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: xOffset, y: yOffset))
    }

    private func insertVideoGap(
        _ blackVideoSource: (track: AVAssetTrack, url: URL)?,
        duration: CMTime,
        range: CMTimeRange,
        at cursor: CMTime,
        into videoTrack: AVMutableCompositionTrack
    ) throws {
        guard let blackVideoSource else {
            videoTrack.insertEmptyTimeRange(range)
            return
        }

        try videoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: blackVideoSource.track,
            at: cursor
        )
    }

    private static func makeBlackVideoFile(
        durationSeconds: Double,
        width: Int,
        height: Int,
        averageBitRate: Int
    ) throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quietline-black-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let compressionProperties: [String: Any] = [
            AVVideoAverageBitRateKey: averageBitRate,
            AVVideoMaxKeyFrameIntervalKey: 1
        ]

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: compressionProperties
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        guard writer.canAdd(input) else {
            throw TimelineComposerError.videoTrackCreationFailed
        }
        writer.add(input)

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )

        guard writer.startWriting() else {
            throw writer.error ?? TimelineComposerError.videoTrackCreationFailed
        }
        writer.startSession(atSourceTime: .zero)

        let seconds = max(durationSeconds, 0.1)
        let framesPerSecond: Int32 = 1
        let frameCount = max(Int(ceil(seconds)) + 2, 2)

        for index in 0..<frameCount {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.005)
            }

            let presentationTime = CMTime(value: CMTimeValue(index), timescale: framesPerSecond)
            guard let pixelBuffer = makeBlackPixelBuffer(from: adaptor.pixelBufferPool, width: width, height: height),
                  adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                input.markAsFinished()
                writer.cancelWriting()
                throw writer.error ?? TimelineComposerError.videoTrackCreationFailed
            }
        }

        input.markAsFinished()

        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        guard writer.status == .completed else {
            throw writer.error ?? TimelineComposerError.videoTrackCreationFailed
        }

        return outputURL
    }

    private static func makeBlackPixelBuffer(
        from pool: CVPixelBufferPool?,
        width: Int,
        height: Int
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        if let pool {
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess else {
                return nil
            }
        } else {
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
            guard CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &pixelBuffer) == kCVReturnSuccess else {
                return nil
            }
        }

        guard let pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
            memset(baseAddress, 0, CVPixelBufferGetDataSize(pixelBuffer))
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        return pixelBuffer
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
