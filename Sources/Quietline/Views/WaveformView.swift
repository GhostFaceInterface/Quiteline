import SwiftUI

struct WaveformView: View {
    let samples: [Float]

    var body: some View {
        Canvas { context, size in
            let step = size.width / CGFloat(max(samples.count, 1))
            let midY = size.height / 2
            let activeGradient = Gradient(colors: [QuietlineTheme.accentSoft, QuietlineTheme.accent])
            let shading = GraphicsContext.Shading.linearGradient(
                activeGradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: size.height)
            )

            for index in samples.indices {
                let amplitude = max(CGFloat(samples[index]), 0.02)
                let x = CGFloat(index) * step + (step * 0.5)
                let barWidth = max(step * 0.7, 1.2)
                let barHeight = max((size.height - 20) * amplitude, 5)
                let rect = CGRect(
                    x: x - barWidth / 2,
                    y: midY - barHeight / 2,
                    width: barWidth,
                    height: barHeight
                )
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                context.fill(path, with: shading)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(QuietlineTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(QuietlineTheme.border, lineWidth: 1)
                )
        )
    }
}
