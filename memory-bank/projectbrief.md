# Project Brief

## Project
Quietline, SwiftUI ve AVFoundation tabanli bir macOS audio birlestirme ve duzenleme uygulamasidir.

## Core Goals
- Audio ve video dosyalarindan sesi import etmek
- Klipleri siralamak, kirpmak, ses seviyesini ayarlamak ve fade eklemek
- Timeline onizlemesi ile sonucu dinlemek
- Waveform uzerinden klip duzenlemek
- Sonucu `.m4a`, `.caf` veya video gerekiyorsa `.mp4` olarak export etmek

## Current UX Direction
- Hafif, kompakt ve editor odakli bir macOS arayuzu
- Solda klip listesi, sagda playback ve waveform editor
- Scroll edilebilir waveform ve dogrudan bolge silme

## Active Requirements
- Soldan klip secildiginde oynatma o klibin baslangicina gitmeli
- Timeline waveform klipler arasinda devam etmeli; secili klibin sonunda sonraki klibe gecis gorulebilmeli
- `Space` oynat/durdur olmali, ancak yazi girilen alanlarda devre disi kalmali
- Export formati kullanici tarafindan audio veya video olarak secilebilmeli; video export secildiginde audio-only bolumlerde siyah goruntu kullanilmali
