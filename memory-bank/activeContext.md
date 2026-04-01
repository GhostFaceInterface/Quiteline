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
- Timeline composer klip-bazli audio track yapisina gecirildi; ses seviyesi ve fade degisikliklerinin preview/export tarafinda gercekten uygulanmasi hedeflendi
- Preview rebuild artik oynatma konumunu sifirlamiyor; slider ile ses degistirirken ayni bolgede dinleyerek test etmek mumkun
- `1.0` uzeri clip volume icin gain katmanlara ayrildi; ornegin `1.33x` bir tam-volume ve bir `0.33` volume track olarak miksleniyor
- Volume kontrolune perceptual gain egri eklendi; `1.33` kontrol degeri artik daha yuksek, daha duyulur bir efektif boost uretiyor
- Gain layer ayristirma ust limiti artirildi ve boost egri dB benzeri daha sert yorumlanmaya baslandi
- Waveform cut mantigina boundary snap ve minimum remainder kurali eklendi; clip kenarinda kalan cok kisa artiklar artik ayri klip olarak birakilmamali
- AudioWaveformService import sirasinda global peak amplitude degeri de cikarmaya basladi
- MediaClip modeline `peakAmplitudeEstimate` eklendi ve geriye donuk decode destegi verildi
- Ses artisi artik klibin tahmini tepe seviyesine gore guvenli tavanda clamp ediliyor; amac output clipping ve bozulmayi onlemek
- Secili klip basligi artik secilebilir ve kopyalanabilir; sidebar klip kartlarina da sag tik ile ad/yol kopyalama eklendi

## Important Notes
- Editor artik tek ana waveform kullaniyor; onceki iki-katmanli waveform yapisi kaldirildi
- Onceki `space` denemesi event monitor ile yapildi ve geri alindi
- Yeni `space` cozumü uygulama yuzeyi odaktayken aktif, export dosya adi alani odaktayken devre disi
- `swift run` senaryosunda menu cubugunda baska uygulama aktif kalirsa once app aktivasyonu dogrulanmali
- Undo/redo kisayollari yalnizca uygulama aktifken ve first responder bir `NSTextView` degilken yakalaniyor; amac yazi alanlarinin yerel undo davranisini bozmamak
- Waveform secimi icin drag anchor secili klip araligina clamp ediliyor; seek ise tum timeline uzerinde kalmaya devam ediyor
- Ses slider'i yalnizca UI state degil; composer rebuild sonrasi player item audioMix zincirine bagli olmalı
- `AVMutableAudioMixInputParameters` tarafinda boost davranisi belirsiz olabilecegi icin paralel track layering tercih edildi
- UI'da ses alani artik efektif miks gain'ini gosteriyor; kontrol degeri ile duysal etki birebir lineer degil
- Onceki implementasyonda boost layer sayisi `4` ile sinirliydi; bu da yuksek ses artisini erken bastiriyordu
- Onceki cut implementasyonunda clip kenarina cok yakin secimler 00:00 gibi gorunen mikro klipler uretebiliyordu
- Eski volume implementasyonunda sadece istenen gain buyutuluyordu; clip peak'i dikkate alinmadigi icin distortion ve "sesler birbirine girme" olusabiliyordu

## Next Steps
- Gercek medya dosyalariyla timeline waveform seek davranisini manuel test et
- `Space` kisayolunun text-entry davranisini manuel test et
- Gerekirse timeline waveform icine otomatik scroll-to-playhead davranisi ekle
- Undo/redo akisini import, trim, ses, fade, silme ve klip tasima uzerinde manuel dogrula
- Hassas waveform seciminin gercek uzun medya dosyalarinda rahat kullanilip kullanilmadigini manuel dogrula
- Ses slider'inin hem preview hem export sonucunda kulakla manuel dogrulamasini yap
