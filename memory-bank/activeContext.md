# Active Context

## Current Task
1. `AGENTS.md` talebine gore memory-bank yapisini kurmak
2. Timeline waveform'da secili klibin sonundan sonraki klibe gecisi mumkun kilmak
3. `Space` icin daha guvenli bir oynat/durdur cozumü bulmak
4. Proje duzenlemeleri icin `Cmd/Ctrl+Z` ve redo mekanizmasi eklemek

## Recent Changes
- Arayuz daha kompakt hale getirildi
- Tek ana, scroll edilebilir timeline waveform editor eklendi
- Klibin ortasindan bolge secip silme destegi eklendi
- Sol listedeki klibe tiklayinca preview o klibin basina gidiyor
- Klibe ozel renkler eklendi
- Memory-bank cekirdek dosyalari olusturuldu
- Coklu waveform karmasasi kaldirildi; tek ana waveform uzerinde timeline gezisi ve secim birlestirildi
- Timeline seek sirasinda secili klip oynatma zamanina gore otomatik degisiyor
- `Space` icin gizli keyboard shortcut yerine odak kontrollu SwiftUI `onKeyPress(.space)` yaklasimi eklendi
- Uygulama launch ve ilk gorunumde foreground app olarak aktive ediliyor; amac Finder/Quick Look odagini kapmak
- Timeline waveform zoom mantigi yeniden ayarlandi; minimum zoom artik viewport fit'e daha yakin
- Snapshot tabanli undo/redo altyapisi eklendi
- `Geri Al` / `Ileri Al` butonlari header'a eklendi
- `Cmd+Z`, `Ctrl+Z`, `Cmd+Shift+Z`, `Ctrl+Shift+Z` icin pencere-ici local key monitor eklendi
- Slider duzenlemeleri tek history adimi olacak sekilde gruplanmaya baslandi
- Timeline waveform secimi secili klibin araligina kilitlendi; clip sinirini asan secimler artik komsu klibe tasinmiyor
- Waveform kesme araci tum klibi silemeyecek sekilde korumaya alindi; tam clip silme icin yan listedeki `Sil` kullanilmali
- Click/drag ayrimi artik piksel bazli; kucuk ve hassas secimler saniye esitigi yerine imlec hareketine gore tanimlaniyor

## Important Notes
- Editor artik tek ana waveform kullaniyor; onceki iki-katmanli waveform yapisi kaldirildi
- Onceki `space` denemesi event monitor ile yapildi ve geri alindi
- Yeni `space` cozumü uygulama yuzeyi odaktayken aktif, export dosya adi alani odaktayken devre disi
- `swift run` senaryosunda menu cubugunda baska uygulama aktif kalirsa once app aktivasyonu dogrulanmali
- Undo/redo kisayollari yalnizca uygulama aktifken ve first responder bir `NSTextView` degilken yakalaniyor; amac yazi alanlarinin yerel undo davranisini bozmamak
- Waveform secimi icin drag anchor secili klip araligina clamp ediliyor; seek ise tum timeline uzerinde kalmaya devam ediyor

## Next Steps
- Gercek medya dosyalariyla timeline waveform seek davranisini manuel test et
- `Space` kisayolunun text-entry davranisini manuel test et
- Gerekirse timeline waveform icine otomatik scroll-to-playhead davranisi ekle
- Undo/redo akisini import, trim, ses, fade, silme ve klip tasima uzerinde manuel dogrula
- Hassas waveform seciminin gercek uzun medya dosyalarinda rahat kullanilip kullanilmadigini manuel dogrula
