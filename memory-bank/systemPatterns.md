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

## Emerging Pattern
- Tek ana waveform yaklasimi tercih edilir:
  - Ana waveform tum klipleri ard arda gosterir
  - Secili klip sadece highlight ve kontrol paneli ile temsil edilir
  - Seek ve secim ayni waveform yuzeyinde yapilir
