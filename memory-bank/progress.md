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

## In Progress
- Gercek kullanimda timeline waveform ve `space` davranisinin manuel dogrulanmasi
- Undo/redo davranisinin gercek duzenleme akisinda manuel dogrulanmasi
- Hassas waveform seciminin gercek kullanimda dogrulanmasi

## Known Issues
- `Space` kisayolunun gercek kullanımdaki Finder/Quick Look etkilesimi kullanici tarafinda tekrar kontrol edilmeli
- Export servisinde Swift 6 actor/sendable uyarilari var

## Validation State
- Son genel build basarili
- Timeline waveform ve keyboard shortcut degisikliklerinden sonra build tekrar basarili
