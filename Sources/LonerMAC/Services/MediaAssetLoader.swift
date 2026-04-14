import AVFoundation
import Foundation

enum MediaAssetLoaderError: LocalizedError {
    case noAudioTrack(URL)
    case invalidDuration(URL)

    var errorDescription: String? {
        switch self {
        case let .noAudioTrack(url):
            return "\(url.lastPathComponent) dosyasinda kullanilabilir bir ses izi bulunamadi."
        case let .invalidDuration(url):
            return "\(url.lastPathComponent) icin gecerli bir sure okunamadi."
        }
    }
}

public struct MediaAssetLoader {
    private let waveformService = AudioWaveformService()

    public init() {}

    @MainActor
    public func loadClip(from url: URL) async throws -> MediaClip {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = duration.seconds

        guard seconds.isFinite, seconds > 0 else {
            throw MediaAssetLoaderError.invalidDuration(url)
        }

        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = audioTracks.first else {
            throw MediaAssetLoaderError.noAudioTrack(url)
        }

        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let videoMetadata = try await loadVideoMetadata(from: videoTracks.first)

        let waveformSamples: [Float]
        let peakAmplitudeEstimate: Float
        do {
            let analysis = try waveformService.generateSamples(
                from: asset,
                audioTrack: audioTrack,
                durationSeconds: seconds
            )
            waveformSamples = analysis.normalizedSamples
            peakAmplitudeEstimate = analysis.peakAmplitude
        } catch {
            waveformSamples = Array(repeating: 0.12, count: 480)
            peakAmplitudeEstimate = 0.9
        }

        return MediaClip(
            sourceURL: url,
            displayName: url.deletingPathExtension().lastPathComponent,
            durationSeconds: seconds,
            trimEnd: seconds,
            peakAmplitudeEstimate: Double(peakAmplitudeEstimate),
            waveformSamples: waveformSamples,
            hasVideo: videoMetadata.hasVideo,
            videoWidth: videoMetadata.width,
            videoHeight: videoMetadata.height
        )
    }

    @MainActor
    private func loadVideoMetadata(from videoTrack: AVAssetTrack?) async throws -> (hasVideo: Bool, width: Double, height: Double) {
        guard let videoTrack else {
            return (false, 0, 0)
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let width = abs(transformedSize.width)
        let height = abs(transformedSize.height)

        return (true, Double(width), Double(height))
    }
}
