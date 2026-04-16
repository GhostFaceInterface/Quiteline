@preconcurrency import AVFoundation
@preconcurrency import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ProjectViewModel: ObservableObject {
    @Published var clips: [MediaClip] = []
    @Published var selectedClipID: UUID?
    @Published var isImporterPresented = false
    @Published var isDropTargeted = false
    @Published var isBusy = false
    @Published var isExporting = false
    @Published var exportProgress: Float = 0
    @Published var playbackTime: Double = 0
    @Published var isPlaying = false
    @Published var totalDuration: Double = 0
    @Published var exportSettings = ExportSettings()
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var waveformSelection: ClosedRange<Double>?
    @Published var waveformZoom: Double = 0.2
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    let player = AVPlayer()
    let supportedImportTypes: [UTType] = [
        .audio,
        .movie,
        .video,
        .audiovisualContent
    ]

    private let loader = MediaAssetLoader()
    private let composer = TimelineComposer()
    private let exportService = ExportService()
    private let persistenceService = ProjectPersistenceService()

    private var previewTask: Task<Void, Never>?
    private var playbackMonitorTask: Task<Void, Never>?
    private var clipOffsets: [UUID: Double] = [:]
    private var accessedURLs: [URL] = []
    private var undoStack: [EditorSnapshot] = []
    private var redoStack: [EditorSnapshot] = []
    private var pendingContinuousEditSnapshot: EditorSnapshot?

    private struct EditorSnapshot: Equatable {
        let clips: [MediaClip]
        let selectedClipID: UUID?
        let waveformSelection: ClosedRange<Double>?
        let exportSettings: ExportSettings
    }

    init() {
        startPlaybackMonitor()
    }

    deinit {
        previewTask?.cancel()
        playbackMonitorTask?.cancel()

        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }

    var selectedClip: MediaClip? {
        guard let selectedClipID else {
            return nil
        }

        return clips.first(where: { $0.id == selectedClipID })
    }

    var canMoveSelectedClipUp: Bool {
        guard let index = selectedClipIndex else {
            return false
        }

        return index > 0
    }

    var canMoveSelectedClipDown: Bool {
        guard let index = selectedClipIndex else {
            return false
        }

        return index < clips.count - 1
    }

    var playbackProgress: Double {
        guard totalDuration > 0 else {
            return 0
        }

        return min(max(playbackTime / totalDuration, 0), 1)
    }

    var selectedClipLocalPlaybackTime: Double? {
        guard let clip = selectedClip,
              let offset = clipOffsets[clip.id] else {
            return nil
        }

        let localTime = playbackTime - offset
        guard localTime >= 0, localTime <= clip.effectiveDuration else {
            return nil
        }

        return localTime
    }

    var selectedClipSourcePlaybackTime: Double? {
        guard let clip = selectedClip,
              let localTime = selectedClipLocalPlaybackTime else {
            return nil
        }

        return clip.trimStart + localTime
    }

    var selectedClipTimelineRange: ClosedRange<Double>? {
        guard let clip = selectedClip,
              let offset = clipOffsets[clip.id] else {
            return nil
        }

        return offset...(offset + clip.effectiveDuration)
    }

    func handleImport(result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            Task {
                await importMedia(from: urls)
            }
        case let .failure(error):
            errorMessage = error.localizedDescription
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else {
            return false
        }

        Task {
            let urls = await loadDroppedURLs(from: fileProviders)
            await importMedia(from: urls)
        }

        return true
    }

    func importMedia(from urls: [URL]) async {
        guard !urls.isEmpty else {
            return
        }

        isBusy = true
        errorMessage = nil
        successMessage = nil

        var importedClips: [MediaClip] = []
        var failures: [String] = []

        for url in urls {
            do {
                if url.startAccessingSecurityScopedResource(), !accessedURLs.contains(url) {
                    accessedURLs.append(url)
                }

                let clip = try await loader.loadClip(from: url)
                importedClips.append(clip)
            } catch {
                failures.append(error.localizedDescription)
            }
        }

        if !importedClips.isEmpty {
            registerUndoSnapshot()
            clips.append(contentsOf: importedClips)
        }

        if selectedClipID == nil {
            selectedClipID = clips.first?.id
        }

        if importedClips.isEmpty {
            errorMessage = failures.joined(separator: "\n")
        } else {
            successMessage = "\(importedClips.count) medya dosyasi eklendi."
            if !failures.isEmpty {
                errorMessage = failures.joined(separator: "\n")
            }
        }

        isBusy = false
        schedulePreviewRefresh()
    }

    func selectClip(_ clip: MediaClip) {
        selectedClipID = clip.id
        waveformSelection = nil

        if let offset = clipOffsets[clip.id] {
            let target = CMTime(seconds: offset, preferredTimescale: 600)
            player.seek(to: target)
            playbackTime = offset

            if isPlaying {
                player.play()
            }
        }
    }

    func removeSelectedClip() {
        guard let index = selectedClipIndex else {
            return
        }

        registerUndoSnapshot()
        clips.remove(at: index)
        waveformSelection = nil

        if clips.isEmpty {
            selectedClipID = nil
            player.replaceCurrentItem(with: nil)
            totalDuration = 0
            playbackTime = 0
            isPlaying = false
            clipOffsets = [:]
        } else {
            selectedClipID = clips[min(index, clips.count - 1)].id
            schedulePreviewRefresh()
        }
    }

    func moveSelectedClipUp() {
        guard let index = selectedClipIndex, index > 0 else {
            return
        }

        registerUndoSnapshot()
        clips.swapAt(index, index - 1)
        schedulePreviewRefresh()
    }

    func moveSelectedClipDown() {
        guard let index = selectedClipIndex, index < clips.count - 1 else {
            return
        }

        registerUndoSnapshot()
        clips.swapAt(index, index + 1)
        schedulePreviewRefresh()
    }

    func updateTrimStart(_ newValue: Double) {
        updateSelectedClip { clip in
            let upperBound = max(clip.trimEnd - 0.1, 0)
            clip.trimStart = min(max(newValue, 0), upperBound)
        }
    }

    func updateTrimEnd(_ newValue: Double) {
        updateSelectedClip { clip in
            let lowerBound = min(clip.trimStart + 0.1, clip.durationSeconds)
            clip.trimEnd = max(min(newValue, clip.durationSeconds), lowerBound)
        }
    }

    func updateVolume(_ newValue: Double) {
        updateSelectedClip { clip in
            clip.volume = min(max(newValue, 0), 2)
        }
    }

    func updateFadeIn(_ newValue: Double) {
        updateSelectedClip { clip in
            clip.fadeInDuration = min(max(newValue, 0), clip.effectiveDuration)
        }
    }

    func updateFadeOut(_ newValue: Double) {
        updateSelectedClip { clip in
            clip.fadeOutDuration = min(max(newValue, 0), clip.effectiveDuration)
        }
    }

    func updateSilenceDuration(_ newValue: Double) {
        updateSelectedClip { clip in
            guard clip.isSilence else {
                return
            }

            let duration = max(newValue, 0.25)
            clip.trimStart = 0
            clip.trimEnd = duration
        }
    }

    func seekToStart() {
        player.seek(to: .zero)
        playbackTime = 0
        syncSelectedClip(to: 0, clearWaveformSelection: true)
    }

    func playTimeline() {
        player.play()
        isPlaying = true
    }

    func pauseTimeline() {
        player.pause()
        isPlaying = false
        let currentTime = player.currentTime().seconds
        playbackTime = currentTime.isFinite ? max(currentTime, 0) : 0
    }

    func togglePlayback() {
        if isPlaying {
            pauseTimeline()
        } else {
            playTimeline()
        }
    }

    func previewSelectedClip() {
        guard let selectedClipID, let offset = clipOffsets[selectedClipID] else {
            player.seek(to: .zero)
            playbackTime = 0
            player.play()
            isPlaying = true
            return
        }

        player.seek(to: CMTime(seconds: offset, preferredTimescale: 600))
        playbackTime = offset
        player.play()
        isPlaying = true
    }

    func seekSelectedClip(to sourceTime: Double) {
        guard let clip = selectedClip,
              let offset = clipOffsets[clip.id] else {
            return
        }

        let clampedSourceTime = min(max(sourceTime, clip.trimStart), clip.trimEnd)
        let localTime = clampedSourceTime - clip.trimStart
        let timelineTime = offset + localTime
        let target = CMTime(seconds: timelineTime, preferredTimescale: 600)
        player.seek(to: target)
        playbackTime = timelineTime
        syncSelectedClip(to: timelineTime)
    }

    func seekTimeline(to timelineTime: Double) {
        let clampedTime = min(max(timelineTime, 0), totalDuration)
        let target = CMTime(seconds: clampedTime, preferredTimescale: 600)
        player.seek(to: target)
        playbackTime = clampedTime
        syncSelectedClip(to: clampedTime)
    }

    func updateTimelineSelection(start: Double, end: Double) {
        let lower = min(start, end)
        let upper = max(start, end)

        guard let startClip = clipContainingTimelineTime(lower) else {
            waveformSelection = nil
            return
        }

        let clip = startClip.clip
        let clipRange = startClip.range
        let clampedLower = max(lower, clipRange.lowerBound)
        let clampedUpper = min(upper, clipRange.upperBound)

        selectedClipID = clip.id

        if clampedUpper - clampedLower < 0.04 {
            waveformSelection = nil
            return
        }

        waveformSelection = (clampedLower - clipRange.lowerBound)...(clampedUpper - clipRange.lowerBound)
    }

    func updateWaveformSelection(start: Double, end: Double) {
        guard let clip = selectedClip else {
            waveformSelection = nil
            return
        }

        let lower = min(max(min(start, end), 0), clip.effectiveDuration)
        let upper = min(max(max(start, end), 0), clip.effectiveDuration)

        if upper - lower < 0.04 {
            waveformSelection = nil
        } else {
            waveformSelection = lower...upper
        }
    }

    func clearWaveformSelection() {
        waveformSelection = nil
    }

    func removeSelectedWaveformRange() {
        guard let index = selectedClipIndex,
              let selection = waveformSelection else {
            return
        }

        let clip = clips[index]
        guard !clip.isSilence else {
            errorMessage = "Sessizlik klibinde bolge silme kullanilamaz."
            return
        }

        let boundarySnapDuration = min(max(clip.effectiveDuration * 0.004, 0.12), 0.45)
        let minimumSegmentDuration = 0.05
        let minimumRemainderDuration = max(boundarySnapDuration, 0.18)

        var absoluteStart = min(max(clip.trimStart + selection.lowerBound, clip.trimStart), clip.trimEnd)
        var absoluteEnd = min(max(clip.trimStart + selection.upperBound, clip.trimStart), clip.trimEnd)

        if absoluteStart - clip.trimStart <= boundarySnapDuration {
            absoluteStart = clip.trimStart
        }

        if clip.trimEnd - absoluteEnd <= boundarySnapDuration {
            absoluteEnd = clip.trimEnd
        }

        guard absoluteEnd - absoluteStart >= minimumSegmentDuration else {
            waveformSelection = nil
            return
        }

        let leftDuration = absoluteStart - clip.trimStart
        let rightDuration = clip.trimEnd - absoluteEnd

        registerUndoSnapshot()

        if leftDuration < minimumRemainderDuration, rightDuration < minimumRemainderDuration {
            waveformSelection = nil
            errorMessage = "Tum klibi silmek icin soldaki Sil dugmesini kullanin."
            successMessage = nil
            return
        } else if leftDuration < minimumRemainderDuration {
            clips[index] = clip.duplicated(
                trimStart: absoluteEnd,
                fadeInDuration: 0
            )
            selectedClipID = clips[index].id
        } else if rightDuration < minimumRemainderDuration {
            clips[index] = clip.duplicated(
                trimEnd: absoluteStart,
                fadeOutDuration: 0
            )
            selectedClipID = clips[index].id
        } else {
            let leftClip = clip.duplicated(
                trimEnd: absoluteStart,
                fadeOutDuration: 0
            )
            let rightClip = clip.duplicated(
                trimStart: absoluteEnd,
                fadeInDuration: 0
            )
            clips.remove(at: index)
            clips.insert(contentsOf: [leftClip, rightClip], at: index)
            selectedClipID = rightClip.id
        }

        waveformSelection = nil
        successMessage = "Secilen ses bolgesi cikartildi."
        errorMessage = nil
        schedulePreviewRefresh()
    }

    func exportTimeline() {
        guard !clips.isEmpty else {
            errorMessage = "Export oncesinde en az bir klip eklemelisiniz."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export Konumu ve Dosya Adi"
        panel.prompt = "Export Et"
        panel.nameFieldLabel = "Dosya adi:"
        panel.nameFieldStringValue = exportSettings.suggestedFileName
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [UTType(filenameExtension: exportSettings.format.fileExtension) ?? .audio]

        guard panel.runModal() == .OK, let pickedURL = panel.url else {
            return
        }

        let url = exportSettings.resolvedURL(from: pickedURL)

        Task {
            await performExport(to: url)
        }
    }

    func addSilenceClip(duration: Double = 2) {
        let silenceClip = MediaClip.silence(durationSeconds: duration)

        registerUndoSnapshot()

        if let index = selectedClipIndex {
            clips.insert(silenceClip, at: index + 1)
        } else {
            clips.append(silenceClip)
        }

        selectedClipID = silenceClip.id
        waveformSelection = nil
        successMessage = "Sessizlik klibi eklendi."
        schedulePreviewRefresh()
    }

    func saveProject() {
        let panel = NSSavePanel()
        panel.title = "Projeyi Kaydet"
        panel.prompt = "Kaydet"
        panel.nameFieldLabel = "Proje dosyasi:"
        panel.nameFieldStringValue = "Quietline Project.json"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [UTType.json]

        guard panel.runModal() == .OK, let pickedURL = panel.url else {
            return
        }

        let url = pickedURL.pathExtension.lowercased() == "json"
            ? pickedURL
            : pickedURL.appendingPathExtension("json")

        do {
            let project = SavedProject(clips: clips, exportSettings: exportSettings)
            try persistenceService.save(project: project, to: url)
            successMessage = "Proje kaydedildi: \(url.lastPathComponent)"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openProject() {
        let panel = NSOpenPanel()
        panel.title = "Projeyi Ac"
        panel.prompt = "Ac"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType.json]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let project = try persistenceService.load(from: url)
            registerUndoSnapshot()
            clips = project.clips
            exportSettings = project.exportSettings
            selectedClipID = clips.first?.id
            waveformSelection = nil

            for clip in clips {
                guard let sourceURL = clip.sourceURL else {
                    continue
                }

                if sourceURL.startAccessingSecurityScopedResource(), !accessedURLs.contains(sourceURL) {
                    accessedURLs.append(sourceURL)
                }
            }

            successMessage = "Proje acildi: \(url.lastPathComponent)"
            errorMessage = nil
            schedulePreviewRefresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateExportFormat(_ format: ExportFormat) {
        guard exportSettings.format != format else {
            return
        }

        registerUndoSnapshot()
        exportSettings.format = format
        successMessage = nil
    }

    func beginContinuousEdit() {
        guard pendingContinuousEditSnapshot == nil else {
            return
        }

        pendingContinuousEditSnapshot = makeSnapshot()
    }

    func endContinuousEdit() {
        guard let snapshot = pendingContinuousEditSnapshot else {
            return
        }

        pendingContinuousEditSnapshot = nil
        if snapshot != makeSnapshot() {
            pushUndoSnapshot(snapshot)
        } else {
            updateHistoryAvailability()
        }
    }

    func undo() {
        endContinuousEdit()

        guard let snapshot = undoStack.popLast() else {
            return
        }

        let currentSnapshot = makeSnapshot()
        if redoStack.last != currentSnapshot {
            redoStack.append(currentSnapshot)
        }

        applySnapshot(snapshot)
        successMessage = "Geri alindi."
        errorMessage = nil
        updateHistoryAvailability()
    }

    func redo() {
        endContinuousEdit()

        guard let snapshot = redoStack.popLast() else {
            return
        }

        let currentSnapshot = makeSnapshot()
        if undoStack.last != currentSnapshot {
            undoStack.append(currentSnapshot)
        }

        applySnapshot(snapshot)
        successMessage = "Tekrar uygulandi."
        errorMessage = nil
        updateHistoryAvailability()
    }

    private var selectedClipIndex: Int? {
        guard let selectedClipID else {
            return nil
        }

        return clips.firstIndex(where: { $0.id == selectedClipID })
    }

    private func updateSelectedClip(_ update: (inout MediaClip) -> Void) {
        guard let index = selectedClipIndex else {
            return
        }

        registerUndoSnapshot()
        update(&clips[index])
        waveformSelection = nil
        successMessage = nil
        schedulePreviewRefresh()
    }

    private func registerUndoSnapshot() {
        guard pendingContinuousEditSnapshot == nil else {
            return
        }

        pushUndoSnapshot(makeSnapshot())
    }

    private func pushUndoSnapshot(_ snapshot: EditorSnapshot) {
        guard undoStack.last != snapshot else {
            updateHistoryAvailability()
            return
        }

        undoStack.append(snapshot)

        if undoStack.count > 100 {
            undoStack.removeFirst(undoStack.count - 100)
        }

        redoStack.removeAll()
        updateHistoryAvailability()
    }

    private func makeSnapshot() -> EditorSnapshot {
        EditorSnapshot(
            clips: clips,
            selectedClipID: selectedClipID,
            waveformSelection: waveformSelection,
            exportSettings: exportSettings
        )
    }

    private func applySnapshot(_ snapshot: EditorSnapshot) {
        clips = snapshot.clips
        selectedClipID = snapshot.selectedClipID.flatMap { id in
            snapshot.clips.contains(where: { $0.id == id }) ? id : snapshot.clips.first?.id
        } ?? snapshot.clips.first?.id
        waveformSelection = snapshot.waveformSelection
        exportSettings = snapshot.exportSettings
        schedulePreviewRefresh()
    }

    private func updateHistoryAvailability() {
        canUndo = !undoStack.isEmpty || pendingContinuousEditSnapshot != nil
        canRedo = !redoStack.isEmpty
    }

    private func schedulePreviewRefresh() {
        previewTask?.cancel()
        previewTask = Task { [weak self] in
            guard let self else {
                return
            }

            try? await Task.sleep(for: .milliseconds(240))
            guard !Task.isCancelled else {
                return
            }

            await self.rebuildPreview(from: self.clips)
        }
    }

    private func rebuildPreview(from snapshot: [MediaClip]) async {
        if snapshot.isEmpty {
            player.pause()
            player.replaceCurrentItem(with: nil)
            clipOffsets = [:]
            totalDuration = 0
            playbackTime = 0
            isPlaying = false
            return
        }

        isBusy = true
        errorMessage = nil
        let previousPlaybackTime = playbackTime
        let shouldResumePlayback = isPlaying

        do {
            let build = try await composer.build(from: snapshot)
            let playerItem = AVPlayerItem(asset: build.composition)
            playerItem.audioMix = build.audioMix
            player.pause()
            player.replaceCurrentItem(with: playerItem)
            clipOffsets = build.clipOffsets
            totalDuration = build.totalDuration
            let restoredTime = min(max(previousPlaybackTime, 0), build.totalDuration)
            let targetTime = CMTime(seconds: restoredTime, preferredTimescale: 600)
            _ = await player.seek(to: targetTime)
            playbackTime = restoredTime
            syncSelectedClip(to: restoredTime)

            if shouldResumePlayback {
                player.play()
                isPlaying = true
            } else {
                isPlaying = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isBusy = false
    }

    private func performExport(to url: URL) async {
        isExporting = true
        errorMessage = nil
        successMessage = nil
        exportProgress = 0

        do {
            let build = try await composer.build(from: clips, includeVideo: exportSettings.format.isVideo)
            defer {
                for temporaryURL in build.temporaryURLs {
                    try? FileManager.default.removeItem(at: temporaryURL)
                }
            }

            try await exportService.export(
                composition: build.composition,
                audioMix: build.audioMix,
                videoComposition: build.videoComposition,
                to: url,
                format: exportSettings.format
            ) { [weak self] progress in
                self?.exportProgress = progress
            }
            successMessage = "Export tamamlandi: \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }

    private func startPlaybackMonitor() {
        playbackMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                let currentTime = self.player.currentTime().seconds
                if currentTime.isFinite {
                    self.playbackTime = min(max(currentTime, 0), self.totalDuration)
                    self.syncSelectedClip(to: self.playbackTime)
                }

                self.isPlaying = self.player.timeControlStatus == .playing

                if self.player.timeControlStatus != .playing,
                   self.totalDuration > 0,
                   self.playbackTime > self.totalDuration - 0.05 {
                    self.playbackTime = self.totalDuration
                }

                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func loadDroppedURLs(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []

        for provider in providers {
            if let url = await loadDroppedURL(from: provider) {
                urls.append(url)
            }
        }

        return urls
    }

    private func loadDroppedURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                    return
                }

                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private func clipContainingTimelineTime(_ timelineTime: Double) -> (clip: MediaClip, range: ClosedRange<Double>)? {
        let sortedOffsets = clipOffsets.sorted { $0.value < $1.value }

        for (index, entry) in sortedOffsets.enumerated() {
            guard let clip = clips.first(where: { $0.id == entry.key }) else {
                continue
            }

            let start = entry.value
            let end: Double

            if index < sortedOffsets.count - 1 {
                end = sortedOffsets[index + 1].value
            } else {
                end = start + clip.effectiveDuration
            }

            let isWithinRange: Bool
            if index < sortedOffsets.count - 1 {
                isWithinRange = timelineTime >= start && timelineTime < end
            } else {
                isWithinRange = timelineTime >= start && timelineTime <= end
            }

            if isWithinRange {
                return (clip, start...end)
            }
        }

        return nil
    }

    private func syncSelectedClip(to timelineTime: Double, clearWaveformSelection: Bool = false) {
        if let result = clipContainingTimelineTime(timelineTime) {
            if selectedClipID != result.clip.id {
                selectedClipID = result.clip.id
                if clearWaveformSelection {
                    waveformSelection = nil
                }
            }
        }
    }
}
