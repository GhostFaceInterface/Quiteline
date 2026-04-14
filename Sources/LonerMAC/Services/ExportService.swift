@preconcurrency import AVFoundation
import Foundation

public struct ExportService {
    public init() {}

    @MainActor
    public func export(
        composition: AVMutableComposition,
        audioMix: AVMutableAudioMix,
        videoComposition: AVMutableVideoComposition? = nil,
        to outputURL: URL,
        format: ExportFormat,
        progressHandler: @escaping @MainActor (Float) -> Void
    ) async throws {
        switch format {
        case .m4a:
            try await exportCompressedAudio(
                composition: composition,
                audioMix: audioMix,
                to: outputURL,
                format: format,
                progressHandler: progressHandler
            )
        case .caf:
            try await exportLinearPCM(
                composition: composition,
                audioMix: audioMix,
                to: outputURL,
                progressHandler: progressHandler
            )
        case .mp4:
            try await exportVideo(
                composition: composition,
                audioMix: audioMix,
                videoComposition: videoComposition,
                to: outputURL,
                format: format,
                progressHandler: progressHandler
            )
        }
    }

    @MainActor
    private func exportCompressedAudio(
        composition: AVMutableComposition,
        audioMix: AVMutableAudioMix,
        to outputURL: URL,
        format: ExportFormat,
        progressHandler: @escaping @MainActor (Float) -> Void
    ) async throws {
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: format.presetName
        ) else {
            throw TimelineComposerError.exportSessionCreationFailed
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        exportSession.audioMix = audioMix
        exportSession.outputURL = outputURL
        exportSession.outputFileType = format.fileType
        exportSession.shouldOptimizeForNetworkUse = false

        progressHandler(0)

        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                let status = exportSession.status
                progressHandler(exportSession.progress)

                if status == .completed || status == .failed || status == .cancelled {
                    break
                }

                try? await Task.sleep(for: .milliseconds(120))
            }
        }

        defer {
            progressTask.cancel()
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? TimelineComposerError.exportSessionCreationFailed)
                case .cancelled:
                    continuation.resume(throwing: CancellationError())
                default:
                    continuation.resume(throwing: TimelineComposerError.exportSessionCreationFailed)
                }
            }
        }

        progressHandler(1)
    }

    @MainActor
    private func exportLinearPCM(
        composition: AVMutableComposition,
        audioMix: AVMutableAudioMix,
        to outputURL: URL,
        progressHandler: @escaping @MainActor (Float) -> Void
    ) async throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let tracks = try await composition.loadTracks(withMediaType: .audio)
        guard !tracks.isEmpty else {
            throw TimelineComposerError.noPlayableClips
        }

        let reader = try AVAssetReader(asset: composition)
        let readerSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let readerOutput = AVAssetReaderAudioMixOutput(audioTracks: tracks, audioSettings: readerSettings)
        readerOutput.audioMix = audioMix

        guard reader.canAdd(readerOutput) else {
            throw TimelineComposerError.exportSessionCreationFailed
        }
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .caf)
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: readerSettings)
        writerInput.expectsMediaDataInRealTime = false

        guard writer.canAdd(writerInput) else {
            throw TimelineComposerError.exportSessionCreationFailed
        }
        writer.add(writerInput)

        let duration = composition.duration.seconds
        progressHandler(0)

        guard writer.startWriting() else {
            throw writer.error ?? TimelineComposerError.exportSessionCreationFailed
        }
        writer.startSession(atSourceTime: .zero)

        guard reader.startReading() else {
            throw reader.error ?? TimelineComposerError.exportSessionCreationFailed
        }

        let queue = DispatchQueue(label: "lonermac.export.linearpcm")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                        let progress = duration > 0 ? Float(min(max(currentTime / duration, 0), 1)) : 0
                        Task { @MainActor in
                            progressHandler(progress)
                        }

                        if !writerInput.append(sampleBuffer) {
                            reader.cancelReading()
                            writerInput.markAsFinished()
                            continuation.resume(throwing: writer.error ?? TimelineComposerError.exportSessionCreationFailed)
                            return
                        }
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if let error = writer.error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                        return
                    }
                }
            }
        }

        progressHandler(1)
    }

    @MainActor
    private func exportVideo(
        composition: AVMutableComposition,
        audioMix: AVMutableAudioMix,
        videoComposition: AVMutableVideoComposition?,
        to outputURL: URL,
        format: ExportFormat,
        progressHandler: @escaping @MainActor (Float) -> Void
    ) async throws {
        let shouldPassthrough = audioMix.inputParameters.isEmpty

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        if shouldPassthrough {
            do {
                try await runVideoExportSession(
                    composition: composition,
                    audioMix: nil,
                    videoComposition: nil,
                    to: outputURL,
                    format: format,
                    presetName: AVAssetExportPresetPassthrough,
                    progressHandler: progressHandler
                )
                return
            } catch {
                guard let videoComposition else {
                    throw error
                }

                if FileManager.default.fileExists(atPath: outputURL.path) {
                    try FileManager.default.removeItem(at: outputURL)
                }

                try await runVideoExportSession(
                    composition: composition,
                    audioMix: nil,
                    videoComposition: videoComposition,
                    to: outputURL,
                    format: format,
                    presetName: AVAssetExportPreset960x540,
                    progressHandler: progressHandler
                )
                return
            }
        } else {
            try await runVideoExportSession(
                composition: composition,
                audioMix: audioMix,
                videoComposition: videoComposition,
                to: outputURL,
                format: format,
                presetName: AVAssetExportPreset960x540,
                progressHandler: progressHandler
            )
        }
    }

    @MainActor
    private func runVideoExportSession(
        composition: AVMutableComposition,
        audioMix: AVMutableAudioMix?,
        videoComposition: AVMutableVideoComposition?,
        to outputURL: URL,
        format: ExportFormat,
        presetName: String,
        progressHandler: @escaping @MainActor (Float) -> Void
    ) async throws {
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: presetName
        ) else {
            throw TimelineComposerError.exportSessionCreationFailed
        }

        exportSession.audioMix = audioMix
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = format.fileType
        exportSession.shouldOptimizeForNetworkUse = false
        progressHandler(0)

        let progressTask = Task { @MainActor in
            while !Task.isCancelled {
                let status = exportSession.status
                progressHandler(exportSession.progress)

                if status == .completed || status == .failed || status == .cancelled {
                    break
                }

                try? await Task.sleep(for: .milliseconds(120))
            }
        }

        defer {
            progressTask.cancel()
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? TimelineComposerError.exportSessionCreationFailed)
                case .cancelled:
                    continuation.resume(throwing: CancellationError())
                default:
                    continuation.resume(throwing: TimelineComposerError.exportSessionCreationFailed)
                }
            }
        }

        progressHandler(1)
    }
}
