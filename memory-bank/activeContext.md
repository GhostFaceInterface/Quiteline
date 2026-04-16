# Active Context

## Current Task
1. Uygulama adini Quietline olarak sabitlemek
2. Eski marka isimlerini kaynak, paket, bundle, dokuman ve kurulum artefact'lerinden kaldirmak
3. Quietline build, bundle launch ve yerel kurulum akisini dogrulamak

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
- Export formatlarina `MP4 Video` eklendi
- `MediaClip` import sirasinda video izi olup olmadigini ve temel video boyutunu saklamaya basladi
- `TimelineComposer` audio preview icin eski hafif build yolunu koruyor; video export istendiginde video klipleri tek passthrough video track'e yerlestiriyor
- Ses/fade/boost efekti olmayan MP4 export'ta audio klipler de tek passthrough audio track'e yerlestiriliyor; boylece video export audioMix kullanmadan orijinal medyayi kopyalayabiliyor
- MP4 export'ta audio-only ve silence araliklari, timeline'da gercek video varsa passthrough video track boslugu olarak; hic gercek video yoksa 160x90, 1 fps, dusuk bitrate siyah H.264 video ile temsil ediliyor
- Gecici siyah video dosyasi olusturulduysa export tamamlandiktan sonra temizleniyor
- MP4 export dosya boyutu kontrol altina alindi; efektsiz export'ta `AVAssetExportPresetPassthrough`, `audioMix = nil` ve `videoComposition = nil` ile orijinal medya segmentlerinin yeniden encode edilmesi engelleniyor
- MP4 passthrough export'ta gercek video iceren projelerde audio-only/silence araliklari artik video track icinde bos zaman araligi olarak birakiliyor; bu, orijinal video segmentlerini yeniden encode etmeden kopyalama sansini artiriyor ve dusuk cozunurluklu siyah klibin codec/format uyumsuzluguyla export'u bozmasini engelliyor
- Tum proje audio-only ise video format output icin 160x90, 1 fps, dusuk bitrate siyah H.264 gecici video asset'i hala kullaniliyor
- SwiftPM GUI app icin `script/build_and_run.sh` eklendi; script build sonrasi `dist/Quietline.app` bundle yapisini uretip `/usr/bin/open -n` ile foreground macOS app olarak aciyor
- Bundle icin `Info.plist`, ad-hoc codesign denemesi ve `Scripts/GenerateAppIcon.swift` tabanli `AppIcon.icns` uretimi eklendi
- Codex masaustu Run aksiyonu `.codex/environments/environment.toml` icinde `./script/build_and_run.sh` komutuna baglandi
- README calistirma bolumu terminalde `swift run` yerine `.app` bundle, verify ve istege bagli install akisini anlatacak sekilde guncellendi
- `./script/build_and_run.sh --verify` ile build, bundle staging ve foreground launch dogrulandi
- `./script/build_and_run.sh --install` ile bundle `/Users/boe747/Applications/Quietline.app` altina kopyalandi ve kurulu bundle'in ad-hoc imzasi dogrulandi
- Uygulama markasi Quietline olarak degistirildi
- SwiftPM package/product/target adi `Quietline`, kaynak klasoru `Sources/Quietline`, app entrypoint dosyasi `QuietlineApp.swift` oldu
- UI basligi, pencere basligi, varsayilan proje dosyasi, temp dosya prefix'i, dispatch queue label'i ve bundle id `com.quietline.app` olarak guncellendi
- Eski app kopyalari lokal kurulum ve dist klasorlerinden kaldirildi

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
- MP4 video export efektsiz kliplerde sabit render size kullanmiyor; video composition kapali oldugu icin orijinal video segmentleri passthrough export edilir
- Video export icin gecici siyah video yalnizca timeline'da hic gercek video yoksa 160x90, 1 fps ve dusuk bitrate olarak uretilir; gercek video bulunan projelerde audio-only araliklar passthrough track boslugu olarak temsil edilir
- Ses/fade/boost efekti olan MP4 export'ta passthrough kullanilmaz; audioMix gerektigi icin AVFoundation reencode fallback'i devreye girer
- Passthrough export farkli codec, transform veya boyut kombinasyonlarinda gercek medya ile mutlaka kontrol edilmeli; bu yol dosya boyutunu dusurur ama AVFoundation uyumlulugu inputlara bagli olabilir. Passthrough basarisiz olursa `AVAssetExportPreset960x540` videoComposition fallback'i siyah arka planla devreye girer
- Uygulamayi gercek macOS app olarak acmak icin ham SwiftPM executable degil `dist/Quietline.app` bundle'i kullanilmali; `script/build_and_run.sh` bu bundle'i her build'de yeniden sahneler
- Kalici kullanici kurulumu icin `script/build_and_run.sh --install` bundle'i `~/Applications/Quietline.app` altina kopyalar; bu akisin Codex tarafinda kullanici onayi ile calistigi dogrulandi
- Eski marka ismi source tree, package metadata, docs ve lokal app kurulumunda temizlendi

## Next Steps
- Gercek medya dosyalariyla timeline waveform seek davranisini manuel test et
- `Space` kisayolunun text-entry davranisini manuel test et
- Gerekirse timeline waveform icine otomatik scroll-to-playhead davranisi ekle
- Undo/redo akisini import, trim, ses, fade, silme ve klip tasima uzerinde manuel dogrula
- Hassas waveform seciminin gercek uzun medya dosyalarinda rahat kullanilip kullanilmadigini manuel dogrula
- Ses slider'inin hem preview hem export sonucunda kulakla manuel dogrulamasini yap
- MP4 video export'u audio-only, video-only ve karisik input senaryolarinda manuel dogrula
