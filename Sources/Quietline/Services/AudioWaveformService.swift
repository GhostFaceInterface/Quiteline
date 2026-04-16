import AVFoundation
import Foundation

enum AudioWaveformServiceError: LocalizedError {
    case noAudioTrack(URL)
    case readerCreationFailed
    case readerOutputCreationFailed

    var errorDescription: String? {
        switch self {
        case let .noAudioTrack(url):
            return "\(url.lastPathComponent) icin waveform uretecek ses izi bulunamadi."
        case .readerCreationFailed:
            return "Waveform okuyucusu olusturulamadi."
        case .readerOutputCreationFailed:
            return "Waveform cikti okuyucusu olusturulamadi."
        }
    }
}

struct AudioWaveformService {
    struct AnalysisResult {
        let normalizedSamples: [Float]
        let peakAmplitude: Float
    }

    func generateSamples(
        from asset: AVURLAsset,
        audioTrack: AVAssetTrack,
        durationSeconds: Double,
        targetSampleCount: Int = 1800
    ) throws -> AnalysisResult {
        guard durationSeconds > 0 else {
            return AnalysisResult(
                normalizedSamples: Array(repeating: 0.05, count: targetSampleCount),
                peakAmplitude: 0.05
            )
        }

        guard let reader = try? AVAssetReader(asset: asset) else {
            throw AudioWaveformServiceError.readerCreationFailed
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else {
            throw AudioWaveformServiceError.readerOutputCreationFailed
        }

        reader.add(output)
        guard reader.startReading() else {
            throw reader.error ?? AudioWaveformServiceError.readerCreationFailed
        }

        var bucketTotals = Array(repeating: 0.0, count: targetSampleCount)
        var bucketCounts = Array(repeating: 0, count: targetSampleCount)
        var globalPeakAmplitude = 0.0

        while let sampleBuffer = output.copyNextSampleBuffer() {
            defer {
                CMSampleBufferInvalidate(sampleBuffer)
            }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                continue
            }

            var totalLength = 0
            var rawPointer: UnsafeMutablePointer<Int8>?

            let status = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &totalLength,
                dataPointerOut: &rawPointer
            )

            guard status == noErr, let rawPointer else {
                continue
            }

            let sampleCount = totalLength / MemoryLayout<Int16>.stride
            guard sampleCount > 0 else {
                continue
            }

            let samples = rawPointer.withMemoryRebound(to: Int16.self, capacity: sampleCount) {
                UnsafeBufferPointer(start: $0, count: sampleCount)
            }

            var sum = 0.0
            var localPeak = 0.0
            for sample in samples {
                let absoluteSample = Double(abs(Int(sample))) / Double(Int16.max)
                sum += absoluteSample
                localPeak = max(localPeak, absoluteSample)
            }
            globalPeakAmplitude = max(globalPeakAmplitude, localPeak)

            let averageAmplitude = sum / Double(sampleCount) / Double(Int16.max)
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            let sampleDuration = CMSampleBufferGetDuration(sampleBuffer).seconds
            let midpoint = max(presentationTime + max(sampleDuration, 0) * 0.5, 0)
            let progress = min(max(midpoint / durationSeconds, 0), 0.999_999)
            let bucketIndex = min(Int(progress * Double(targetSampleCount)), targetSampleCount - 1)

            bucketTotals[bucketIndex] += averageAmplitude
            bucketCounts[bucketIndex] += 1
        }

        let averaged = zip(bucketTotals, bucketCounts).map { total, count -> Float in
            guard count > 0 else {
                return 0.04
            }

            return Float(total / Double(count))
        }

        let maxValue = averaged.max() ?? 0
        guard maxValue > 0 else {
            return AnalysisResult(
                normalizedSamples: Array(repeating: 0.05, count: targetSampleCount),
                peakAmplitude: Float(max(globalPeakAmplitude, 0.05))
            )
        }

        return AnalysisResult(
            normalizedSamples: averaged.map { max($0 / maxValue, 0.04) },
            peakAmplitude: Float(max(globalPeakAmplitude, 0.05))
        )
    }
}
