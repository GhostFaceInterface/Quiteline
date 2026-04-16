# System Patterns

## App Structure
- SwiftUI tabanli tek pencere uygulamasi
- `ProjectViewModel` tum timeline state ve playback/export akislarini yonetir
- `TimelineComposer` AVMutableComposition ve AVAudioMix olusturur
- `MediaAssetLoader` dosyalari okuyup waveform verisi cikarir
- SwiftPM executable, yerel kullanim icin `script/build_and_run.sh` tarafindan `dist/Quietline.app` bundle'ina paketlenir
- Bundle `Contents/MacOS/Quietline`, `Contents/Info.plist` ve uretilmis `Contents/Resources/AppIcon.icns` yapisini kullanir

## Playback Pattern
- `AVPlayer` preview icin tek kaynak
- `clipOffsets` ile her klibin timeline baslangici tutulur
- Secili klip ve oynatma konumu UI tarafina `@Published` state ile yansir
- Preview rebuild sirasinda player item yenilense bile oynatma konumu korunur; boylece trim/ses/fade degisiklikleri duyularak test edilebilir

## Editing Pattern
- Ayrintili duzenleme secili klip bazli yapilir
- Waveform secimi ve bolge silme `ProjectViewModel` icinde klibi parcaya bolerek uygulanir
- Timeline waveform seek tum timeline uzerinde serbesttir, ancak bolge secimi secili klibin zaman araligina kilitlenir
- Kesme sirasinda clip basi/sonuna yakin secimler sinira snap edilir; boylece anlamsiz mikro artifakt klipler urememeli
- Ses/fade envelope'lari tek ortak track yerine klip-bazli composition track'lere uygulanir; amac preview ve export'ta gain degisikliklerini guvenilir yapmak
- `1.0` ustu gain icin tek parametreye bel baglanmaz; clip birden fazla paralel audio track katmanina bolunerek boost fiziksel olarak mikslenir
- Volume kontrolu lineer degil, perceptual egri ile yorumlanir; amac kucuk slider hareketlerinde daha belirgin duyusal fark vermek
- Gain layer ayristirma ust siniri daha yuksektir; buyuk boost degerleri artik 4x civarinda erken tikanmaz
- Import sirasinda her klip icin yaklasik peak amplitude degeri de cikartilir; boost degeri bu peak'e gore guvenli tavanda sinirlanir
- `mixGain` artik sadece istenen gain degil, clip'in tahmini headroom'una gore clamp edilmis guvenli output gain'idir
- Undo/redo snapshot tabanlidir:
  - Klip listesi, secili klip, waveform secimi ve export format state'i snapshot olarak tutulur
  - Surekli slider hareketleri tek history adimi olacak sekilde gruplanir

## Export Pattern
- Audio export icin mevcut AVMutableComposition + AVMutableAudioMix akisi korunur
- Video export icin `TimelineComposer.build(includeVideo: true)` ayni timeline'a video track'leri de ekler
- MP4 export, kliplerde ses/fade/boost efekti yoksa `AVAssetExportPresetPassthrough` kullanir; amac orijinal video ve audio segmentlerini yeniden encode etmeden ciktiya almak ve dosya boyutu sismesini onlemektir
- Video klipler tek passthrough video track icine timeline sirasiyla yerlestirilir
- Efektsiz MP4 export'ta audio segmentleri tek passthrough audio track icine yerlestirilir; boylece cikti birden fazla audio track uretmez
- Gercek video iceren MP4 passthrough export'ta audio-only veya silence araliklari video track'te bos zaman araligi olarak birakilir; bu, orijinal video segmentlerini kopyalamayi ve codec/format uyumsuzlugundan kacmayi hedefler
- Timeline'da hic gercek video yoksa video format cikti icin 160x90, 1 fps, dusuk bitrate gecici siyah H.264 video uretilir
- Gecici siyah video dosyasi olusturulduysa export tamamlandiktan sonra `ProjectViewModel` tarafinda temizlenir
- Ses/fade/boost efekti olan MP4 export'larda audioMix gerekir; bu durumda mevcut AVFoundation reencode fallback'i kullanilir
- Efektsiz MP4 passthrough basarisiz olursa `ExportService` 960x540 `videoComposition` fallback'i ile yeniden dener; bu fallback siyah arka plani video bosluklari icin de kullanir

## Emerging Pattern
- Tek ana waveform yaklasimi tercih edilir:
  - Ana waveform tum klipleri ard arda gosterir
  - Secili klip sadece highlight ve kontrol paneli ile temsil edilir
  - Seek ve secim ayni waveform yuzeyinde yapilir
- SwiftPM GUI launch icin ham executable yerine app bundle launch tercih edilir:
  - Bundle staging `dist/Quietline.app` altinda yapilir
  - Launch `/usr/bin/open -n dist/Quietline.app` ile yapilir
  - Kalici lokal kurulum gerekiyorsa ayni bundle `~/Applications/Quietline.app` altina kopyalanir
