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

Quietline, birden fazla audio/video kaynağını tek bir timeline üzerinde birleştirip, problemli kısımları hızlıca kesip temiz bir çıktı almanı sağlayan yerel bir macOS uygulaması.

Bu proje sadece teknik bir araç değil — aynı zamanda bir ruh hali.

Hitori Gotoh gibi:
- başta biraz kaotik,
- içeride hafif panik,
- ama iş bitince tertemiz sonuç.

---

<p align="center">
  <img src="https://media.tenor.com/3GZ3gC91crtAAAAC/bocchi-bocchitherock.gif" width="45%">
  <img src="https://media.tenor.com/27031923AAAAC/bocchi-the-rock-anime.gif" width="45%">
</p>

<p align="center">
  <img src="https://media.tenor.com/26998598AAAAC/bocchitherock.gif" width="30%">
  <img src="https://media.tenor.com/27014588AAAAC/bocchi-the-rock.gif" width="30%">
  <img src="https://media.tenor.com/26895031AAAAC/bocchi-bocchitherock.gif" width="30%">
</p>

---

## Sahne

<p align="center">
  <img src="pics%20for%20readme/Ana%20bak%C4%B1%C5%9F.png" width="100%">
</p>

Quietline terminal aracı gibi davranmaz. Açarsın ve çalışır.

Arayüz üç parçadan oluşur:

- **Klipler** → Dosyaları seçtiğin ve sıraladığın yer  
- **Playback** → Oynatma kontrolü  
- **Düzenleyici** → Waveform üzerinden kesme, trim ve ses kontrolü  

---

## Neden Var?

Çünkü klasik araçlar:
- ya fazla ağır  
- ya da basit işler için fazla karmaşık  

Senin ihtiyacın olan şey şu:

- Dosyayı at  
- Waveform’u gör  
- Sorunlu yeri seç  
- Tek hamlede temizle  

Hepsi bu.

---

## Özellikler

- Audio / video import
- Drag & drop destekli çalışma
- Tek timeline üzerinde düzenleme
- Waveform üzerinden seçim
- Trim + ses kontrolü
- Fade in / out
- `.m4a`, `.caf`, `.mp4` export

---

## Kurulum

```bash
./script/build_and_run.sh