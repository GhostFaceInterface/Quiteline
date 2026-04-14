# Tech Context

## Stack
- Swift 6
- SwiftUI
- AVFoundation
- AppKit yalnizca dosya panelleri ve gereken macOS entegrasyonlari icin

## Build
- Swift Package
- Minimum platform: macOS 14
- Ana komut: `swift build`

## Constraints
- AVFoundation export katmaninda Swift 6 `Sendable` uyarilari var, ancak build bloklayici degil
- Klavye kisayollari AppKit/SwiftUI odak davranisi ile dikkatli entegre edilmeli
- Uzun waveform'larda performans icin `Canvas` tercih ediliyor
- MP4 export icin gecici siyah video asset'i yalnizca timeline'da hic gercek video yoksa AVAssetWriter ile uretiliyor ve UI thread'i kilitlememek icin utility priority detached task icinde calistiriliyor
- MP4 export'ta efektsiz kliplerde `AVAssetExportPresetPassthrough` tercih edilmeli; video composition yeniden encode ettigi icin dosya boyutunu kontrolsuz buyutebiliyor
- Gercek video iceren MP4 passthrough export'ta audio-only/silence bolumleri video track boslugu olarak temsil ediliyor; passthrough basarisiz olursa 960x540 videoComposition fallback siyah arka planla tekrar deneniyor
- Hic gercek video olmayan MP4 bolumleri icin gecici siyah video 160x90, 1 fps, dusuk bitrate H.264 olarak uretiliyor
- Ses/fade/boost gerektiren MP4 export audioMix ister; passthrough bu durumda kullanilmamali, reencode fallback beklenir
