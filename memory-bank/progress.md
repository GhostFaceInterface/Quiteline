# Progress

## Working
- Import, reorder, trim, volume, fade, silence, project save/load, export
- Tek ana, scroll edilebilir timeline waveform editor
- Waveform uzerinden bolge secip silme
- Sol klip listesinde secili klibe atlama
- Klipe ozel renk atama
- Timeline seek ile klipler arasi gecis ve secili klibi otomatik guncelleme
- `Space` icin odak kontrollu `onKeyPress` tabanli oynat/durdur kisayolu
- Launch sirasinda foreground aktivasyonu
- Zoom minimumunda timeline'i daha uzak gosteren yeni waveform genislik mantigi
- Snapshot tabanli undo/redo
- Header icinde gorunur `Geri Al` / `Ileri Al` kontrolleri
- `Cmd/Ctrl+Z` ve redo kisayollari
- Secili klibe kilitli waveform secimi
- Kazara tum klibi waveform kesme ile silmeyi engelleyen koruma
- Klip-bazli audio track mix yapisi
- Preview rebuild sonrasinda oynatma konumunu koruma
- `1.0x` ustu boost icin paralel gain-layer miksleme
- Daha agresif perceptual volume egri
- Daha yuksek gain-layer ust siniri
- Clip kenarinda mikro artifakt klipleri engelleyen cut snap davranisi
- Peak-aware safe gain clamp
- Kopyalanabilir klip basligi ve klip karti context menu copy aksiyonlari
- Audio export icin `.m4a` ve `.caf`, video export icin `.mp4` format secimi
- MP4 export'ta audio-only ve silence bolumleri siyah goruntu olarak temsil etme
- Video inputlari timeline'daki siralarina gore MP4 output icine yerlestirme
- Hic gercek video olmayan MP4 export sirasinda gecici siyah video tabani uretip export sonrasi temizleme
- MP4 export icin efektsiz kliplerde passthrough preset; orijinal video/audio segmentlerini yeniden encode etmeden kullanma
- Gercek video bulunmayan MP4 export icin 160x90, 1 fps, dusuk bitrate siyah video placeholder
- Gercek video iceren MP4 passthrough export'ta audio-only/silence araliklarini dusuk cozunurluklu ek video klibi yerine video track boslugu olarak temsil etme
- Hic gercek video olmayan MP4 export'ta 160x90, 1 fps, dusuk bitrate siyah H.264 placeholder kullanmaya devam etme

## In Progress
- Gercek kullanimda timeline waveform ve `space` davranisinin manuel dogrulanmasi
- Undo/redo davranisinin gercek duzenleme akisinda manuel dogrulanmasi
- Hassas waveform seciminin gercek kullanimda dogrulanmasi
- Ses slider'inin preview ve export sonucunda manuel dogrulanmasi
- MP4 video export'un gercek audio-only, video-only ve karisik medya dosyalariyla dosya boyutu dahil manuel dogrulanmasi

## Known Issues
- `Space` kisayolunun gercek kullanımdaki Finder/Quick Look etkilesimi kullanici tarafinda tekrar kontrol edilmeli
- Export servisinde Swift 6 actor/sendable uyarilari var
- MP4 passthrough export farkli codec, transform veya video boyutu karisimlarinda gercek medya ile manuel dogrulanmali; passthrough basarisiz olursa 960x540 reencode fallback devreye girer
- MP4 export'ta ses/fade/boost efekti kullanilirsa audioMix gerektigi icin reencode fallback'i devreye girer

## Validation State
- Son genel build basarili
- Timeline waveform ve keyboard shortcut degisikliklerinden sonra build tekrar basarili
- MP4 video passthrough export degisikliginden sonra `swift build` basarili
- Sentetik AVFoundation smoke testinde iki kisa MP4 ve bir M4A audio-only ara bolum tek video + tek audio track passthrough MP4'e basariyla export edildi; cikti boyutu girdilerin toplamına yakin kaldi
- `ffprobe` yerelde bulunmadigi icin smoke output stream detaylari `ffmpeg -i` ile kontrol edildi
- Audio-only ara bolumu video track boslugu olarak birakan yeni passthrough smoke testi basarili; cikti tek video + tek audio stream olarak olustu ve boyut girdilerin toplamına yakin kaldi
- `swift test` denendi ancak projede `Tests` target'i olmadigi icin SwiftPM `no tests found` hatasiyla cikti; `swift build` basarili
