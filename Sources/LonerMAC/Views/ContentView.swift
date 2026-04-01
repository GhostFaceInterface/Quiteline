import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @FocusState private var focusedField: FocusedField?
    @FocusState private var playbackSurfaceFocused: Bool
    @State private var localKeyMonitor: Any?

    private let controlColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let clipPalette: [Color] = [
        Color(red: 0.78, green: 0.35, blue: 0.25),
        Color(red: 0.33, green: 0.52, blue: 0.48),
        Color(red: 0.58, green: 0.44, blue: 0.73),
        Color(red: 0.79, green: 0.59, blue: 0.24),
        Color(red: 0.29, green: 0.49, blue: 0.74),
        Color(red: 0.67, green: 0.39, blue: 0.48)
    ]

    private enum FocusedField: Hashable {
        case exportFileName
    }

    var body: some View {
        ZStack {
            LonerTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 14) {
                headerBar

                HSplitView {
                    sidebar
                        .frame(minWidth: 280, idealWidth: 300, maxWidth: 340)

                    editor
                        .frame(minWidth: 760)
                }

                footer
            }
            .padding(18)

            if viewModel.isDropTargeted {
                dropOverlay
                    .transition(.opacity)
            }
        }
        .focusable()
        .focused($playbackSurfaceFocused)
        .fileImporter(
            isPresented: $viewModel.isImporterPresented,
            allowedContentTypes: viewModel.supportedImportTypes,
            allowsMultipleSelection: true,
            onCompletion: viewModel.handleImport
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $viewModel.isDropTargeted) { providers in
            viewModel.handleDrop(providers: providers)
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            playbackSurfaceFocused = true
            installLocalKeyMonitorIfNeeded()
        }
        .onDisappear {
            removeLocalKeyMonitor()
        }
        .onTapGesture {
            if focusedField == nil {
                playbackSurfaceFocused = true
            }
        }
        .onKeyPress(.space) {
            guard focusedField == nil,
                  !viewModel.clips.isEmpty,
                  !viewModel.isBusy else {
                return .ignored
            }

            viewModel.togglePlayback()
            playbackSurfaceFocused = true
            return .handled
        }
    }

    private var headerBar: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LonerMAC")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(LonerTheme.textPrimary)

                Text("Audio birlestir, dinle ve dalga gorunumunden direkt duzenle.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(LonerTheme.textSecondary)

                HStack(spacing: 8) {
                    summaryChip(title: "Klip", value: "\(viewModel.clips.count)")
                    summaryChip(title: "Sure", value: TimeFormatter.string(from: viewModel.totalDuration))
                    summaryChip(title: "Format", value: viewModel.exportSettings.format.fileExtension.uppercased())
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                toolbarButton("Geri Al", systemImage: "arrow.uturn.backward") {
                    viewModel.undo()
                }
                .disabled(!viewModel.canUndo)
                toolbarButton("Ileri Al", systemImage: "arrow.uturn.forward") {
                    viewModel.redo()
                }
                .disabled(!viewModel.canRedo)
                toolbarButton("Ac", systemImage: "folder") {
                    viewModel.openProject()
                }
                toolbarButton("Kaydet", systemImage: "square.and.arrow.down") {
                    viewModel.saveProject()
                }
                .disabled(viewModel.clips.isEmpty)
                toolbarButton("Sessizlik", systemImage: "speaker.slash") {
                    viewModel.addSilenceClip()
                }
                toolbarButton("Dosya Ekle", systemImage: "plus") {
                    viewModel.isImporterPresented = true
                }
                Button(action: viewModel.exportTimeline) {
                    Label("Export", systemImage: "arrow.down.circle")
                }
                .buttonStyle(
                    PillButtonStyle(
                        fill: LonerTheme.accent,
                        foreground: .white,
                        stroke: LonerTheme.accent.opacity(0.35)
                    )
                )
                .disabled(viewModel.clips.isEmpty || viewModel.isBusy || viewModel.isExporting)
            }
        }
        .studioPanel(padding: 18, fill: LonerTheme.panel)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Klipler")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                    Text("Sec, sirala ve kirp.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }

                Spacer()

                Text("\(viewModel.clips.count)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(LonerTheme.textPrimary)
            }

            if viewModel.clips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "waveform.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(LonerTheme.accent)
                    Text("Bos proje")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                    Text("Audio veya video dosyalarini ekle ya da Finder'dan buraya birak.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LonerTheme.panelSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(LonerTheme.borderStrong, style: StrokeStyle(lineWidth: 1, dash: [7, 5]))
                        )
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.clips) { clip in
                            clipRow(clip)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            HStack(spacing: 8) {
                sidebarAction("Yukari", systemImage: "arrow.up") {
                    viewModel.moveSelectedClipUp()
                }
                .disabled(!viewModel.canMoveSelectedClipUp)

                sidebarAction("Asagi", systemImage: "arrow.down") {
                    viewModel.moveSelectedClipDown()
                }
                .disabled(!viewModel.canMoveSelectedClipDown)

                Spacer()

                sidebarAction("Sil", systemImage: "trash") {
                    viewModel.removeSelectedClip()
                }
                .disabled(viewModel.selectedClip == nil)
            }
        }
        .studioPanel(fill: LonerTheme.panel)
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                transportBar

                if let clip = viewModel.selectedClip {
                    if clip.isSilence {
                        silenceEditor(clip)
                    } else {
                        mediaEditor(clip)
                    }
                } else {
                    emptyEditor
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var transportBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Playback")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                    Text("Tek tus ile oynat/durdur. Secili klipten baslatmak icin yan butonu kullan.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    compactMetric(title: "Konum", value: TimeFormatter.string(from: viewModel.playbackTime))
                    compactMetric(title: "Durum", value: viewModel.isBusy ? "Hazirlaniyor" : (viewModel.isPlaying ? "Oynuyor" : "Hazir"))
                }
            }

            ProgressView(value: viewModel.playbackProgress)
                .tint(LonerTheme.accent)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            HStack(spacing: 10) {
                Button(action: viewModel.seekToStart) {
                    Image(systemName: "backward.end.fill")
                }
                .buttonStyle(
                    IconButtonStyle(
                        fill: LonerTheme.panelMuted,
                        foreground: LonerTheme.textPrimary
                    )
                )
                .disabled(viewModel.clips.isEmpty)

                Button(action: viewModel.togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                }
                .buttonStyle(
                    IconButtonStyle(
                        fill: LonerTheme.textPrimary,
                        foreground: LonerTheme.panel,
                        stroke: LonerTheme.textPrimary.opacity(0.18),
                        size: 52
                    )
                )
                .disabled(viewModel.clips.isEmpty || viewModel.isBusy)

                Button(action: viewModel.previewSelectedClip) {
                    Label("Secili Klipten Oynat", systemImage: "waveform")
                }
                .buttonStyle(
                    PillButtonStyle(
                        fill: LonerTheme.panelMuted,
                        foreground: LonerTheme.textPrimary,
                        stroke: LonerTheme.borderStrong
                    )
                )
                .disabled(viewModel.selectedClip == nil || viewModel.isBusy)

                Spacer()

                if viewModel.isExporting {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Export %\(Int(viewModel.exportProgress * 100))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LonerTheme.textPrimary)
                        ProgressView(value: Double(viewModel.exportProgress))
                            .frame(width: 140)
                            .tint(LonerTheme.accent)
                    }
                }
            }
        }
        .studioPanel(fill: LonerTheme.panel)
    }

    private func mediaEditor(_ clip: MediaClip) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            waveformCard(clip)
            HStack(alignment: .top, spacing: 14) {
                clipControlPanel(clip)
                exportPanel
            }
        }
    }

    private func silenceEditor(_ clip: MediaClip) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sessizlik Blogu")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(LonerTheme.textPrimary)
                        Text("Timeline icine nefes aldiran bosluk ekler.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(LonerTheme.textSecondary)
                    }
                    Spacer()
                    compactMetric(title: "Sure", value: TimeFormatter.string(from: clip.effectiveDuration))
                }

                WaveformView(samples: clip.waveformSamples)
                    .frame(height: 140)

                sliderCard(
                    title: "Sessizlik Suresi",
                    valueText: TimeFormatter.string(from: clip.effectiveDuration),
                    tint: LonerTheme.accent,
                    range: 0.25...20,
                    onEditingChanged: handleSliderEditingChanged,
                    value: Binding(
                        get: { viewModel.selectedClip?.effectiveDuration ?? 2 },
                        set: { viewModel.updateSilenceDuration($0) }
                    )
                )
            }
            .frame(maxWidth: .infinity)
            .studioPanel(fill: LonerTheme.panel)

            exportPanel
        }
    }

    private func waveformCard(_ clip: MediaClip) -> some View {
        let timelineClips = viewModel.clips.enumerated().reduce(into: [TimelineWaveformClip]()) { partialResult, entry in
            let index = entry.offset
            let clip = entry.element
            let startTime = partialResult.last.map { $0.startTime + $0.duration } ?? 0
            partialResult.append(
                TimelineWaveformClip(
                    id: clip.id,
                    title: clip.displayName,
                    startTime: startTime,
                    duration: clip.effectiveDuration,
                    samples: clip.waveformSamples,
                    color: clipColor(forIndex: index)
                )
            )
        }
        let selection = viewModel.selectedClipTimelineRange.flatMap { range in
            viewModel.waveformSelection.map { (range.lowerBound + $0.lowerBound)...(range.lowerBound + $0.upperBound) }
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.displayName)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                        .lineLimit(2)
                    Text("Waveform uzerinde surukleyerek problemli bolgeyi sec, sonra tek tusla cikart.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }
                .textSelection(.enabled)
                .contextMenu {
                    Button("Metni Kopyala") {
                        copyToPasteboard(clip.displayName)
                    }

                    if let sourceURL = clip.sourceURL {
                        Button("Dosya Yolunu Kopyala") {
                            copyToPasteboard(sourceURL.path)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    compactMetric(title: "Kaynak", value: TimeFormatter.string(from: clip.durationSeconds))
                    compactMetric(title: "Aktif", value: TimeFormatter.string(from: clip.effectiveDuration))
                }
            }

            HStack(spacing: 12) {
                Text("Zoom")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LonerTheme.textSecondary)

                Slider(value: $viewModel.waveformZoom, in: 0...4)
                    .tint(LonerTheme.accent)
                    .frame(maxWidth: 180)

                Text(String(format: "%.1fx", viewModel.waveformZoom))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LonerTheme.textSecondary)

                Spacer()

                if let localTime = viewModel.selectedClipLocalPlaybackTime {
                    Text("Oynatma: \(TimeFormatter.string(from: localTime))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }
            }

            TimelineWaveformView(
                clips: timelineClips,
                totalDuration: viewModel.totalDuration,
                playheadTime: viewModel.playbackTime,
                selectedClipID: viewModel.selectedClipID,
                editableRange: viewModel.selectedClipTimelineRange,
                selection: selection,
                zoom: viewModel.waveformZoom,
                onSeek: { viewModel.seekTimeline(to: $0) },
                onSelectionChange: { range in
                    guard let range else {
                        viewModel.clearWaveformSelection()
                        return
                    }

                    viewModel.updateTimelineSelection(start: range.lowerBound, end: range.upperBound)
                }
            )
            .frame(height: 240)

            HStack(spacing: 10) {
                if let selection = viewModel.waveformSelection {
                    Label(
                        "\(TimeFormatter.string(from: selection.lowerBound)) - \(TimeFormatter.string(from: selection.upperBound))",
                        systemImage: "scissors"
                    )
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LonerTheme.textPrimary)

                    Button("Secimi Temizle") {
                        viewModel.clearWaveformSelection()
                    }
                    .buttonStyle(
                        PillButtonStyle(
                            fill: LonerTheme.panelMuted,
                            foreground: LonerTheme.textPrimary
                        )
                    )

                    Button("Secili Bolgeyi Sil") {
                        viewModel.removeSelectedWaveformRange()
                    }
                    .buttonStyle(
                        PillButtonStyle(
                            fill: LonerTheme.accent,
                            foreground: .white,
                            stroke: LonerTheme.accent.opacity(0.35)
                        )
                    )
                } else {
                    Text("Trackpad ile yatay kaydir. Tikla ve surukle: bolge sec. Tek tik: oynatma kafasini o noktaya gotur.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }

                Spacer()
            }
        }
        .studioPanel(fill: LonerTheme.panel)
    }

    private func clipControlPanel(_ clip: MediaClip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Klip Kontrolleri")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                    Text("Trim, ses ve fade ayarlari.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }
                Spacer()
            }

            LazyVGrid(columns: controlColumns, spacing: 12) {
                sliderCard(
                    title: "Baslangic",
                    valueText: TimeFormatter.string(from: clip.trimStart),
                    tint: LonerTheme.accentSecondary,
                    range: 0...clip.durationSeconds,
                    onEditingChanged: handleSliderEditingChanged,
                    value: Binding(
                        get: { viewModel.selectedClip?.trimStart ?? 0 },
                        set: { viewModel.updateTrimStart($0) }
                    )
                )

                sliderCard(
                    title: "Bitis",
                    valueText: TimeFormatter.string(from: clip.trimEnd),
                    tint: LonerTheme.accent,
                    range: 0...clip.durationSeconds,
                    onEditingChanged: handleSliderEditingChanged,
                    value: Binding(
                        get: { viewModel.selectedClip?.trimEnd ?? clip.durationSeconds },
                        set: { viewModel.updateTrimEnd($0) }
                    )
                )

                sliderCard(
                    title: "Ses",
                    valueText: String(format: "%.2fx", clip.mixGain),
                    tint: LonerTheme.accentSoft,
                    range: 0...2,
                    onEditingChanged: handleSliderEditingChanged,
                    value: Binding(
                        get: { viewModel.selectedClip?.volume ?? 1 },
                        set: { viewModel.updateVolume($0) }
                    )
                )

                sliderCard(
                    title: "Fade In",
                    valueText: TimeFormatter.string(from: clip.fadeInDuration),
                    tint: LonerTheme.accentSecondary,
                    range: 0...clip.effectiveDuration,
                    onEditingChanged: handleSliderEditingChanged,
                    value: Binding(
                        get: { viewModel.selectedClip?.fadeInDuration ?? 0 },
                        set: { viewModel.updateFadeIn($0) }
                    )
                )

                sliderCard(
                    title: "Fade Out",
                    valueText: TimeFormatter.string(from: clip.fadeOutDuration),
                    tint: LonerTheme.accent,
                    range: 0...clip.effectiveDuration,
                    onEditingChanged: handleSliderEditingChanged,
                    value: Binding(
                        get: { viewModel.selectedClip?.fadeOutDuration ?? 0 },
                        set: { viewModel.updateFadeOut($0) }
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .studioPanel(fill: LonerTheme.panel)
    }

    private var exportPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                    Text("Dosya adi ve format.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Dosya Adi")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LonerTheme.textSecondary)

                TextField("MergedAudio", text: $viewModel.exportSettings.fileName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(LonerTheme.textPrimary)
                    .focused($focusedField, equals: .exportFileName)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LonerTheme.panelSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(LonerTheme.border, lineWidth: 1)
                            )
                    )
            }

            HStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button(format.title) {
                        viewModel.updateExportFormat(format)
                    }
                    .buttonStyle(
                        PillButtonStyle(
                            fill: viewModel.exportSettings.format == format ? LonerTheme.textPrimary : LonerTheme.panelMuted,
                            foreground: viewModel.exportSettings.format == format ? .white : LonerTheme.textPrimary,
                            stroke: viewModel.exportSettings.format == format ? LonerTheme.textPrimary.opacity(0.15) : LonerTheme.border
                        )
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                compactMetric(title: "Cikti", value: viewModel.exportSettings.suggestedFileName)
                compactMetric(title: "Uzanti", value: ".\(viewModel.exportSettings.format.fileExtension)")
            }

            Spacer(minLength: 0)
        }
        .frame(width: 280, alignment: .topLeading)
        .studioPanel(fill: LonerTheme.panel)
    }

    private var emptyEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duzenleyici hazir")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(LonerTheme.textPrimary)
            Text("Soldan bir klip secildiginde scroll edilebilir waveform, oynatma kafasi ve bolge silme araclari burada acilir.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(LonerTheme.textSecondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
        .studioPanel(fill: LonerTheme.panel)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                StatusDot(color: LonerTheme.danger)
                Text(errorMessage)
                    .foregroundStyle(LonerTheme.textPrimary)
            } else if let successMessage = viewModel.successMessage, !successMessage.isEmpty {
                StatusDot(color: LonerTheme.success)
                Text(successMessage)
                    .foregroundStyle(LonerTheme.textPrimary)
            } else {
                StatusDot(color: viewModel.isPlaying ? LonerTheme.accent : LonerTheme.accentSecondary)
                Text("Dalga gorunumu uzerinden dogrudan secim yapip problemli sesleri cikartabilirsin.")
                    .foregroundStyle(LonerTheme.textSecondary)
            }

            Spacer()

            Text("Scroll waveform + direct cut")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(LonerTheme.textSecondary)
        }
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .studioPanel(padding: 14, fill: LonerTheme.panel)
    }

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.74))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(LonerTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
            )
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(LonerTheme.accent)
                    Text("Dosyalari buraya birak")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(LonerTheme.textPrimary)
                    Text("Audio ve video dosyalari otomatik olarak klip listesine eklenir.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(LonerTheme.textSecondary)
                }
                .padding(32)
            }
            .padding(22)
    }

    private func toolbarButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(
            PillButtonStyle(
                fill: LonerTheme.panelMuted,
                foreground: LonerTheme.textPrimary,
                stroke: LonerTheme.borderStrong
            )
        )
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LonerTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(LonerTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(LonerTheme.panelSecondary)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(LonerTheme.border, lineWidth: 1)
                )
        )
    }

    private func clipRow(_ clip: MediaClip) -> some View {
        let isSelected = viewModel.selectedClipID == clip.id
        let color = clipColor(for: clip)

        return Button {
            viewModel.selectClip(clip)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(clip.isSilence ? "SILENCE" : "MEDIA")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.white.opacity(0.8) : color)
                        Text(clip.displayName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.white : LonerTheme.textPrimary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    Text(String(format: "x%.2f", clip.volume))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : LonerTheme.textSecondary)
                    Text(String(format: "etki %.2fx", clip.mixGain))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : LonerTheme.textSecondary)
                }

                HStack {
                    Label(TimeFormatter.string(from: clip.effectiveDuration), systemImage: "clock")
                    Spacer()
                    Text(clip.isSilence ? "gap" : "ready")
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white.opacity(0.85) : LonerTheme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? color : LonerTheme.panelSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? color.opacity(0.95) : color.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Klip Adini Kopyala") {
                copyToPasteboard(clip.displayName)
            }

            if let sourceURL = clip.sourceURL {
                Button("Dosya Yolunu Kopyala") {
                    copyToPasteboard(sourceURL.path)
                }
            }
        }
    }

    private func sidebarAction(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(
            PillButtonStyle(
                fill: LonerTheme.panelMuted,
                foreground: LonerTheme.textPrimary
            )
        )
    }

    private func compactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LonerTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(LonerTheme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LonerTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LonerTheme.border, lineWidth: 1)
                )
        )
    }

    private func sliderCard(
        title: String,
        valueText: String,
        tint: Color,
        range: ClosedRange<Double>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        value: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LonerTheme.textPrimary)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LonerTheme.textSecondary)
            }

            Slider(value: value, in: range, onEditingChanged: onEditingChanged)
                .tint(tint)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LonerTheme.panelSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LonerTheme.border, lineWidth: 1)
                )
        )
    }

    private func clipColor(for clip: MediaClip) -> Color {
        guard let index = viewModel.clips.firstIndex(where: { $0.id == clip.id }) else {
            return LonerTheme.accent
        }

        return clipColor(forIndex: index)
    }

    private func clipColor(forIndex index: Int) -> Color {
        clipPalette[index % clipPalette.count]
    }

    private func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        viewModel.successMessage = "Metin panoya kopyalandi."
        viewModel.errorMessage = nil
    }

    private func handleSliderEditingChanged(_ isEditing: Bool) {
        if isEditing {
            viewModel.beginContinuousEdit()
        } else {
            viewModel.endContinuousEdit()
        }
    }

    private func installLocalKeyMonitorIfNeeded() {
        guard localKeyMonitor == nil else {
            return
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleLocalKeyEvent(event)
        }
    }

    private func removeLocalKeyMonitor() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }

    private func handleLocalKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard NSApp.isActive,
              !(NSApp.keyWindow?.firstResponder is NSTextView) else {
            return event
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard event.charactersIgnoringModifiers?.lowercased() == "z" else {
            return event
        }

        if (modifiers == [.command] || modifiers == [.control]), viewModel.canUndo {
            viewModel.undo()
            return nil
        }

        if (modifiers == [.command, .shift] || modifiers == [.control, .shift]), viewModel.canRedo {
            viewModel.redo()
            return nil
        }

        return event
    }
}
