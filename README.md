# Quietline

SwiftUI ve AVFoundation tabanli bir macOS audio birlestirme uygulamasi.

## Tasarim Dili
- Daha hafif, daha sakin ve daha kompakt bir duzen kullanir; buyuk hero bloklar yerine ustte komut cubugu, solda klip listesi ve sagda editor alani bulunur.
- Secili klip icin scroll edilebilir waveform editor, oynatma kafasi ve surukleyerek bolge secme akisi vardir.
- Problemli bir orta bolge secilip tek aksiyonla cikarilabilir; uygulama gerekirse klibi iki parcaya boler.

## Mevcut Ozellikler
- Audio ve video dosyalarindan ses import etme
- Finder uzerinden surukle-birak ile import etme
- Klipleri siralama
- Trim baslangic / bitis duzenleme
- Waveform uzerinden klip durumunu gorselleme
- Ses seviyesi ayarlama
- Fade in / fade out ayarlama
- Timeline icine sessizlik klibi ekleme
- Timeline onizleme oynatma ve ilerleme gostergesi
- Export ayar modeli ile varsayilan dosya adi ve format belirleme
- Export konumu ve dosya adi secerek `.m4a` veya `.caf` cikti alma
- Export sirasinda progress gostergesi
- Projeyi JSON olarak kaydetme ve tekrar acma

## Calistirma
```bash
./script/build_and_run.sh
```

Bu komut SwiftPM ciktisini `dist/Quietline.app` olarak paketler ve uygulamayi
normal bir macOS app bundle'i olarak acar. Finder'dan dogrudan acmak icin:

```bash
./script/build_and_run.sh --bundle
open dist/Quietline.app
```

Uygulamayi kullanici Applications klasorune kopyalamak icin:

```bash
./script/build_and_run.sh --install
```

Xcode ile acmak isterseniz `Package.swift` dosyasini dogrudan acabilirsiniz.

## Kullanim
1. Uygulamayi acin.
2. `Dosya Ekle` ile audio veya video dosyalari secin ya da Finder'dan pencereye surukleyip birakin.
3. Soldaki listeden bir klip secin.
4. Sag editor alaninda waveform uzerinde tiklayarak oynatma kafasini istediginiz noktaya goturun.
5. Problemli bir sesi cikarmak icin waveform uzerinde tiklayip surukleyerek bolge secin, sonra `Secili Bolgeyi Sil` butonunu kullanin.
6. Alt panelde trim, ses seviyesi, fade in ve fade out ayarlarini yapin.
7. Tek ana oynatma tusu ile dinleyin; secili klipten baslatmak icin `Secili Klipten Oynat` butonunu kullanin.
8. `Export` alanindan varsayilan dosya adini ve formati belirleyin.
9. `Export` ile kayit konumu ve dosya adini secip ciktiyi alin.

## Dogrulama
```bash
swift build
./script/build_and_run.sh --verify
swiftc -o /tmp/quietline-smoke \
  Sources/Quietline/Models/MediaClip.swift \
  Sources/Quietline/Models/ExportSettings.swift \
  Sources/Quietline/Models/SavedProject.swift \
  Sources/Quietline/Models/TimelineBuildResult.swift \
  Sources/Quietline/Services/AudioWaveformService.swift \
  Sources/Quietline/Services/MediaAssetLoader.swift \
  Sources/Quietline/Services/TimelineComposer.swift \
  Sources/Quietline/Services/ProjectPersistenceService.swift \
  Sources/Quietline/Services/ExportService.swift \
  Scripts/SmokeCheck.swift
/tmp/quietline-smoke
```

## Performans
Buyuk proje davranis notlari icin [PERFORMANCE.md](./PERFORMANCE.md) dosyasina bakin.
