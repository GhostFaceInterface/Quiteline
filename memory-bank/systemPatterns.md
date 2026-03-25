# System Patterns

## App Structure
- SwiftUI tabanli tek pencere uygulamasi
- `ProjectViewModel` tum timeline state ve playback/export akislarini yonetir
- `TimelineComposer` AVMutableComposition ve AVAudioMix olusturur
- `MediaAssetLoader` dosyalari okuyup waveform verisi cikarir

## Playback Pattern
- `AVPlayer` preview icin tek kaynak
- `clipOffsets` ile her klibin timeline baslangici tutulur
- Secili klip ve oynatma konumu UI tarafina `@Published` state ile yansir

## Editing Pattern
- Ayrintili duzenleme secili klip bazli yapilir
- Waveform secimi ve bolge silme `ProjectViewModel` icinde klibi parcaya bolerek uygulanir
- Timeline waveform seek tum timeline uzerinde serbesttir, ancak bolge secimi secili klibin zaman araligina kilitlenir
- Undo/redo snapshot tabanlidir:
  - Klip listesi, secili klip, waveform secimi ve export format state'i snapshot olarak tutulur
  - Surekli slider hareketleri tek history adimi olacak sekilde gruplanir

## Emerging Pattern
- Tek ana waveform yaklasimi tercih edilir:
  - Ana waveform tum klipleri ard arda gosterir
  - Secili klip sadece highlight ve kontrol paneli ile temsil edilir
  - Seek ve secim ayni waveform yuzeyinde yapilir
