import SwiftUI

struct TimelineWaveformClip: Identifiable {
    let id: UUID
    let title: String
    let startTime: Double
    let duration: Double
    let samples: [Float]
    let color: Color
}

struct TimelineWaveformView: View {
    let clips: [TimelineWaveformClip]
    let totalDuration: Double
    let playheadTime: Double
    let selectedClipID: UUID?
    let editableRange: ClosedRange<Double>?
    let selection: ClosedRange<Double>?
    let zoom: Double
    let onSeek: (Double) -> Void
    let onSelectionChange: (ClosedRange<Double>?) -> Void

    @State private var dragAnchorTime: Double?

    private let minimumSelectionDistance: CGFloat = 5
    private let minimumSelectionDuration: Double = 0.02

    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = max(geometry.size.width, 720)
            let contentWidth = viewportWidth * CGFloat(1 + (zoom * 2.5))

            ScrollView(.horizontal) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(QuietlineTheme.panelSecondary)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(QuietlineTheme.border, lineWidth: 1)

                    gridOverlay
                        .padding(.vertical, 16)

                    Canvas { context, size in
                        let height = size.height

                        for clip in clips {
                            let startX = xPosition(for: clip.startTime, width: size.width)
                            let clipWidth = max(xPosition(for: clip.startTime + clip.duration, width: size.width) - startX, 40)
                            let visibleSamples = strideSamples(clip.samples, targetCount: max(Int(clipWidth / 4), 20))
                            let step = clipWidth / CGFloat(max(visibleSamples.count, 1))
                            let centerY = height / 2
                            let gradient = Gradient(colors: [clip.color.opacity(0.34), clip.color])
                            let shading = GraphicsContext.Shading.linearGradient(
                                gradient,
                                startPoint: CGPoint(x: startX, y: 0),
                                endPoint: CGPoint(x: startX, y: height)
                            )

                            let clipRect = CGRect(x: startX, y: 14, width: clipWidth, height: height - 28)
                            let clipPath = Path(roundedRect: clipRect, cornerRadius: 14)
                            context.fill(clipPath, with: .color(clip.color.opacity(selectedClipID == clip.id ? 0.16 : 0.08)))
                            context.stroke(clipPath, with: .color(clip.color.opacity(selectedClipID == clip.id ? 0.55 : 0.22)), lineWidth: 1)

                            for index in visibleSamples.indices {
                                let amplitude = max(CGFloat(visibleSamples[index]), 0.04)
                                let barHeight = max((height - 42) * amplitude, 4)
                                let barRect = CGRect(
                                    x: startX + CGFloat(index) * step + step * 0.22,
                                    y: centerY - barHeight / 2,
                                    width: max(step * 0.48, 1.6),
                                    height: barHeight
                                )
                                let barPath = Path(roundedRect: barRect, cornerRadius: 2)
                                context.fill(barPath, with: shading)
                            }
                        }

                        let playheadX = xPosition(for: playheadTime, width: size.width)
                        let playheadRect = CGRect(x: playheadX - 1.25, y: 8, width: 2.5, height: height - 16)
                        context.fill(Path(roundedRect: playheadRect, cornerRadius: 1.25), with: .color(QuietlineTheme.textPrimary))
                    }

                    labelsOverlay(width: contentWidth)
                    selectionOverlay(width: contentWidth, height: 240)
                }
                .frame(width: contentWidth, height: 240)
                .contentShape(Rectangle())
                .gesture(selectionGesture(contentWidth: contentWidth))
            }
            .scrollIndicators(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var gridOverlay: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(index == 2 ? QuietlineTheme.borderStrong : QuietlineTheme.border.opacity(0.6))
                    .frame(height: 1)
                if index < 3 {
                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func labelsOverlay(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(clips) { clip in
                let startX = xPosition(for: clip.startTime, width: width)
                let clipWidth = max(xPosition(for: clip.startTime + clip.duration, width: width) - startX - 16, 52)

                Text(clip.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(QuietlineTheme.textSecondary)
                    .lineLimit(1)
                    .frame(width: clipWidth, alignment: .leading)
                    .offset(x: startX + 8, y: 18)
            }
        }
        .allowsHitTesting(false)
    }

    private func selectionOverlay(width: CGFloat, height: CGFloat) -> some View {
        guard let selection else {
            return AnyView(EmptyView())
        }

        let startX = xPosition(for: selection.lowerBound, width: width)
        let selectionWidth = xPosition(for: selection.upperBound, width: width) - startX

        return AnyView(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(QuietlineTheme.selectionOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(QuietlineTheme.textPrimary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [7, 4]))
                )
                .frame(width: max(selectionWidth, 2), height: height - 34)
                .offset(x: startX, y: 17)
                .allowsHitTesting(false)
        )
    }

    private func selectionGesture(contentWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let startTime = dragAnchorTime ?? clampedEditableTime(
                    for: time(for: value.startLocation.x, width: contentWidth)
                )
                dragAnchorTime = startTime
                let currentTime = clampedEditableTime(
                    for: time(for: value.location.x, width: contentWidth)
                )
                let lower = min(startTime, currentTime)
                let upper = max(startTime, currentTime)
                let dragDistance = abs(value.translation.width)

                if dragDistance >= minimumSelectionDistance,
                   upper - lower >= minimumSelectionDuration {
                    onSelectionChange(lower...upper)
                }
            }
            .onEnded { value in
                let startTime = dragAnchorTime ?? clampedEditableTime(
                    for: time(for: value.startLocation.x, width: contentWidth)
                )
                let currentTime = clampedEditableTime(
                    for: time(for: value.location.x, width: contentWidth)
                )
                let lower = min(startTime, currentTime)
                let upper = max(startTime, currentTime)
                let dragDistance = abs(value.translation.width)

                if dragDistance < minimumSelectionDistance || upper - lower < minimumSelectionDuration {
                    onSelectionChange(nil)
                    onSeek(time(for: value.location.x, width: contentWidth))
                } else {
                    onSelectionChange(lower...upper)
                }

                dragAnchorTime = nil
            }
    }

    private func xPosition(for time: Double, width: CGFloat) -> CGFloat {
        guard totalDuration > 0 else {
            return 0
        }

        return CGFloat(min(max(time / totalDuration, 0), 1)) * width
    }

    private func time(for xPosition: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else {
            return 0
        }

        return min(max(Double(xPosition / width) * totalDuration, 0), totalDuration)
    }

    private func clampedEditableTime(for time: Double) -> Double {
        guard let editableRange else {
            return time
        }

        return min(max(time, editableRange.lowerBound), editableRange.upperBound)
    }

    private func strideSamples(_ samples: [Float], targetCount: Int) -> [Float] {
        guard samples.count > targetCount, targetCount > 0 else {
            return samples
        }

        let strideValue = max(samples.count / targetCount, 1)
        return stride(from: 0, to: samples.count, by: strideValue).map { samples[$0] }
    }
}
