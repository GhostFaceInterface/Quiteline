# Quietline

<p align="center">
  <img src="pics%20for%20readme/hitori%20gotoh%20wallpaper.png" alt="Hitori Gotoh inspired Quietline wallpaper" width="100%">
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-ff78b4?style=for-the-badge">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-f7ce46?style=for-the-badge">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-native-60d5df?style=for-the-badge">
  <img alt="AVFoundation" src="https://img.shields.io/badge/AVFoundation-audio%20timeline-211c2c?style=for-the-badge">
</p>

Quietline, birden fazla audio/video dosyasındaki sesleri tek bir timeline üzerinde birleştirmek, problemli bölgeleri waveform üzerinden kesmek ve sonucu temiz şekilde export etmek için geliştirilmiş yerleşik bir macOS uygulamasıdır.

Tema tarafında çıkış noktası Hitori Gotoh: pembe saç, mavi-sarı toka, sahne korkusu, gitar teli enerjisi ve içeride biriken bütün o "tamam, bunu tek başıma hallederim" hali. Yani uygulama ciddi bir işi yapıyor, ama ruh hali biraz Bocchi panik atak edit masası.

<p align="center">
  <img src="pics%20for%20readme/4c7c669c255123a68c2474ccf5ab7ab9.gif" alt="Bocchi energy gif" width="31%">
  <img src="pics%20for%20readme/anxious-bocchi-the-rock-hitori-goto-gz3gc91crt91pilz.gif" alt="Anxious Hitori Gotoh gif" width="31%">
  <img src="pics%20for%20readme/Bocchi%20patlamas%C4%B1.gif" alt="Bocchi explosion gif" width="31%">
</p>

## Sahne

<p align="center">
  <img src="pics%20for%20readme/Ana%20bak%C4%B1%C5%9F.png" alt="Quietline ana ekran" width="100%">
</p>

Quietline terminalde çalışan bir araç gibi değil, doğrudan tıklayıp açabileceğin bir macOS app olarak paketlenir. Ana düzen üç parçadan oluşur:

- `Klipler`: import edilen dosyaları seçme, sıralama ve silme alanı.
- `Playback`: tek oynatma noktası, başlangıca dönme ve seçili klipten oynatma kontrolleri.
- `Düzenleyici`: scroll edilebilir timeline waveform, seçili bölge silme, trim, ses ve fade kontrolleri.

## Neden Var?

ASMR, konuşma, ambience, gitar, video içinden alınmış sesler ya da "şu dosyanın ortasında rahatsız edici bir tık var" dediğin şeyler için klasik araçlar fazla ağır kalabiliyor. Quietline bu akışı tek pencereye indirir:

- Dosyaları ekle.
- Waveform üzerinde nerede olduğunu gör.
- Sorunlu yeri sürükleyerek seç.
- Tek aksiyonla çıkar.
- Sonucu `.m4a`, `.caf` veya `.mp4` olarak al.

<p align="center">
  <img src="pics%20for%20readme/221703.gif" alt="Hitori Gotoh focus gif" width="45%">
  <img src="pics%20for%20readme/anxious-bocchi-the-rock-hitori-goto-gz3gc91crt91pilz.webp" alt="Hitori Gotoh webp mood" width="45%">
</p>

## Özellikler

- Audio ve video dosyalarından ses import etme
- Finder üzerinden sürükle-bırak ile dosya ekleme
- Klipleri yukarı/aşağı taşıma
- Seçili klipten oynatma
- `Space` ile oynat/durdur
- `Cmd+Z` / `Ctrl+Z` ile geri alma
- `Cmd+Shift+Z` / `Ctrl+Shift+Z` ile ileri alma
- Tek ana timeline waveform üzerinde seek ve seçim
- Waveform üzerinde sürükleyerek problemli bölge seçme
- Seçili bölgeyi klibi parçalayarak çıkarma
- Trim başlangıç/bitiş ayarı
- Ses seviyesi ve güvenli boost
- Fade in / fade out
- `.m4a`, `.caf`, `.mp4` export
- Video export için audio-only bölümlerde kontrollü siyah video davranışı
- macOS `.app` bundle üretimi
- Yerel `~/Applications/Quietline.app` kurulumu

## Kurulum

Gerekenler:

- macOS 14 veya üzeri
- Xcode Command Line Tools
- Swift 6 toolchain

Projeyi build edip doğrudan app olarak açmak için:

```bash
./script/build_and_run.sh
```

Bu komut SwiftPM çıktısını `dist/Quietline.app` olarak paketler ve uygulamayı normal bir macOS uygulaması gibi açar.

Sadece bundle üretmek istersen:

```bash
./script/build_and_run.sh --bundle
open dist/Quietline.app
```

Kendi kullanıcı Applications klasörüne kurmak istersen:

```bash
./script/build_and_run.sh --install
```

Kurulumdan sonra uygulama şu konumda olur:

```text
~/Applications/Quietline.app
```

Xcode ile geliştirmek istersen `Package.swift` dosyasını doğrudan açabilirsin.

## Kullanım

<p align="center">
  <img src="pics%20for%20readme/Kullan%C4%B1m.png" alt="Quietline kullanım akışı" width="100%">
</p>

1. `Dosya Ekle` ile audio veya video dosyalarını seç.
2. Dosyaları Finder'dan pencereye sürükleyip bırakabilirsin.
3. Soldaki `Klipler` listesinden çalışacağın klibi seç.
4. Waveform üzerinde tek tıkla oynatma kafasını istediğin noktaya taşı.
5. Problemli bir bölgeyi çıkarmak için waveform üzerinde sürükleyerek seçim yap.
6. `Seçili Bölgeyi Sil` ile o kısmı timeline'dan çıkar.
7. Trim, ses, fade in ve fade out ayarlarını düzenle.
8. `Seçili Klipten Oynat` ile sadece aktif klipten başlayarak dinle.
9. Export formatını seç.
10. `Export` ile çıktıyı al.

<p align="center">
  <img src="pics%20for%20readme/detay.png" alt="Quietline detay ekranı" width="100%">
</p>

## Kullanım Opsiyonları

### Import

Quietline şu akışları hedefler:

- Audio dosyası ekle: `.m4a`, `.mp3`, `.wav`, `.caf` ve macOS'un AVFoundation ile okuyabildiği diğer ses formatları.
- Video dosyası ekle: videonun ses izini timeline'a al.
- Karışık proje kur: audio ve video kaynaklarını aynı timeline üzerinde birleştir.

### Playback

- Ana oynat/durdur butonu tüm timeline için çalışır.
- `Space` oynat/durdur kısayoludur.
- `Seçili Klipten Oynat`, seçili klibin başlangıcına gidip oradan dinletir.
- Timeline seek, klip sınırlarını geçebilir; böylece klipler arası geçişi duyabilirsin.

### Editing

- Waveform üzerinde sürükleme: bölge seçimi.
- Waveform üzerinde tek tık: playhead taşıma.
- `Seçili Bölgeyi Sil`: seçilen aralığı çıkarır.
- Kenara çok yakın seçimlerde mikro klip üretmemek için boundary snap uygulanır.
- Ses slider'ı sadece UI değeri değildir; preview ve export mix zincirine yansır.

### Export

| Format | Ne için iyi? | Not |
| --- | --- | --- |
| `M4A Audio` | Genel kullanım, paylaşım, küçük dosya | Varsayılan pratik çıktı |
| `CAF PCM` | Daha ham/işlenebilir ses çıktısı | Büyük dosya üretebilir |
| `MP4 Video` | Video timeline veya video gerektiren platformlar | Audio-only bölümlerde kontrollü siyah video kullanılır |

MP4 tarafında mümkün olduğunda passthrough kullanılır. Ama ses/fade/boost gibi efektler devreye girerse AVFoundation reencode fallback'i çalışabilir.

## Tema

Quietline'ın görsel dili Hitori Gotoh'tan ödünç alınmış birkaç fikrin uygulama arayüzüne çevrilmiş hali:

- Pembe ana vurgu: Hitori saç ve hoodie enerjisi.
- Aqua vurgu: sakin ama hafif panikleyen kontrast.
- Sarı/mavi toka motifi: küçük ama hemen tanınan imza.
- Gitar teli çizgileri: timeline ve waveform hissini güçlendiren arka plan dili.
- Açık pastel kartlar: karanlık editör yerine daha yumuşak, daha okunabilir masaüstü hissi.

<p align="center">
  <img src="pics%20for%20readme/4c7c669c255123a68c2474ccf5ab7ab9.gif" alt="Bocchi loop gif" width="30%">
  <img src="pics%20for%20readme/221703.gif" alt="Bocchi stage gif" width="30%">
  <img src="pics%20for%20readme/Bocchi%20patlamas%C4%B1.gif" alt="Bocchi panic gif" width="30%">
</p>

## Geliştirici Notları

SwiftPM build:

```bash
env CLANG_MODULE_CACHE_PATH=/tmp/clang-module-cache SWIFTPM_ENABLE_PLUGINS=0 swift build
```

App bundle doğrulama:

```bash
./script/build_and_run.sh --verify
```

Kurulu app doğrulama:

```bash
codesign --verify --deep --strict /Users/boe747/Applications/Quietline.app
```

Temel smoke akışı gerekiyorsa:

```bash
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

## Bilinen Notlar

- `swift build` sırasında `ExportService.swift` içinde Swift concurrency / `Sendable` uyarıları görülebilir. Şu an build'i bloklamaz.
- `swift test` için mevcut package içinde ayrı test target'ı yoksa SwiftPM `no tests found` döndürebilir.
- GUI uygulamasını gerçek macOS davranışıyla test etmek için ham executable yerine `.app` bundle üzerinden açmak daha doğru sonuç verir.

## Ruh Hali

Quietline şunu yapmaya çalışır: yalnız başına bir sürü ses klibini toparlamak, kötü yerleri kesmek, sonucu düzgün almak ve bunu yaparken ekrana baktığında "tamam, bu benim küçük pembe edit masam" dedirtmek.

<p align="center">
  <img src="pics%20for%20readme/anxious-bocchi-the-rock-hitori-goto-gz3gc91crt91pilz.gif" alt="Hitori Gotoh anxious closer" width="38%">
</p>
