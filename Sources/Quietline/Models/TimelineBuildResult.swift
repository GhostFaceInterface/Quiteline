import AVFoundation
import Foundation

public struct TimelineBuildResult {
    public let composition: AVMutableComposition
    public let audioMix: AVMutableAudioMix
    public let videoComposition: AVMutableVideoComposition?
    public let clipOffsets: [UUID: Double]
    public let totalDuration: Double
    public let temporaryURLs: [URL]
}
