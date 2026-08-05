# 🎵 SonicWave

### A Modern, Cross-Platform Music Player Built with Flutter

**[Android 7+](#android)** · **[Windows 7+](#windows)** · **[Web](#web)**

[![Release](https://img.shields.io/github/v/release/AnishtayiN/MusicPlayer?style=flat-square&color=8B5CF6)](https://github.com/AnishtayiN/MusicPlayer/releases)
[![Downloads](https://img.shields.io/github/downloads/AnishtayiN/MusicPlayer/total?style=flat-square&color=06B6D4)](https://github.com/AnishtayiN/MusicPlayer/releases)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Electron](https://img.shields.io/badge/Electron-22-47848F?style=flat-square&logo=electron)](https://www.electronjs.org)

---

<p>
  <img src="https://img.shields.io/badge/Dark_Mode-🌙-8B5CF6?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Light_Mode-☀️-F59E0B?style=for-the-badge" />
  <img src="https://img.shields.io/badge/8_Color_Themes-🎨-EC4899?style=for-the-badge" />
</p>

---

## ✨ Overview

**SonicWave** is a sleek, modern music player designed for **Android** and **Windows 7+** with a unified codebase powered by Flutter. It features a stunning UI with dynamic theming, real-time lyrics, a full queue system, and automatic updates delivered via GitHub Releases.

Whether you're listening to your local library or streaming demo tracks, SonicWave delivers a professional-grade experience with zero compromises on design or performance.

---

## 🚀 Features

### 🎧 Playback

| Feature | Description |
|---|---|
| 🔄 **Smart Queue** | Add, remove, and reorder tracks on the fly |
| 🔀 **Shuffle / Repeat** | Off · All · One · Smart shuffle (no repeats) |
| ⚡ **Playback Speed** | 0.5x → 2.0x with real-time adjustment |
| 🔊 **Volume + Mute** | Persistent across sessions |
| ⏰ **Sleep Timer** | 5 / 15 / 30 / 60 min with smooth fade-out |
| 🎯 **Smart Previous** | Replay if > 3s in, else go back |
| 💾 **Resume Playback** | Auto-restore last track & position |

### 🎨 Design

| Feature | Description |
|---|---|
| 🌓 **Dual Themes** | Dark + Light with seamless toggle |
| 🎨 **8 Accent Colors** | Purple, Blue, Pink, Red, Orange, Gold, Green, Teal |
| 🖌️ **Independent Day/Night Accents** | Different colors for each mode |
| 🌈 **Dynamic Palette** | UI adapts to album cover colors |
| 🌀 **Animated Vinyl** | Rotating cover during playback |
| 📊 **Visualizer** | Animated waveform synchronized with music |

### 📚 Library

| Feature | Description |
|---|---|
| 📂 **Folder Picker** | Choose any folder on Android & Windows |
| 🔍 **Smart Search** | Filter by title or artist in real-time |
| ❤️ **Favorites** | Persistent favorites with Hive |
| 📜 **History Tab** | Track recently played songs |
| 🏷️ **Metadata** | Real album art, album name, year, bitrate |
| 📝 **Format Badge** | MP3 / FLAC / WAV / OGG / M4A / AAC / WMA |

### 📝 Lyrics

- **Auto-fetch** from LRCLIB (synced & plain)
- **Local `.lrc` / `.txt`** files next to audio
- **Karaoke Mode** — line-by-line highlight with auto-scroll
- **Manual paste** — add your own lyrics, saved per track

### ⌨️ Shortcuts

| Key | Action |
|---|---|
| `Space` | Play / Pause |
| `Ctrl + →` | Next Track |
| `Ctrl + ←` | Previous Track |
| `↑` / `↓` | Volume Up / Down |
| 🎹 **Media Keys** | Native Windows media key support |

### 🔧 Advanced

| Feature | Description |
|---|---|
| 🪟 **Drag & Drop** | Drop audio files directly onto Windows app |
| 📱 **Share** | Native sharing on Android (WhatsApp, Telegram, etc.) |
| 📁 **Show in Folder** | Reveal file in Explorer (Windows) |
| ✏️ **Rename** | Rename local tracks in-place |
| 🗑️ **Delete** | Remove from disk with confirmation |
| 🔄 **Auto-Update** | Auto-checks GitHub for new versions |

---

## 📱 Supported Platforms

| Platform | Minimum Version | Format |
|---|---|---|
| 🤖 **Android** | 7.0 (API 24) | APK |
| 🪟 **Windows** | 7 SP1+ | EXE Installer |
| 🌐 **Web** | Modern browsers | HTML + JS (Electron wrapper) |

---

## ⚡ Quick Start

### Download Latest Release

👉 **[Download SonicWave](https://github.com/AnishtayiN/MusicPlayer/releases/latest)**

Pick your platform:
- **Android**: `SonicWave-vX.Y.Z-android7plus.apk`
- **Windows**: `SonicWave-vX.Y.Z-windows7plus-setup.exe`

---

## 🛠️ Build from Source

### Prerequisites

- **Flutter** 3.24+
- **Node.js** 18+ (for Windows builds)
- **JDK** 17 (for Android builds)

### Setup

~~~bash
git clone https://github.com/AnishtayiN/MusicPlayer.git
cd MusicPlayer
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
~~~

### Run Locally

**Android:**
~~~bash
flutter run
~~~

**Web (Chrome):**
~~~bash
flutter run -d chrome
~~~

**Windows (Electron):**
~~~bash
flutter build web --release
npm install
npx electron .
~~~

### Build Release Artifacts

**Android APK:**
~~~bash
flutter build apk --release
~~~

**Windows Installer:**
~~~bash
flutter build web --release
npm run build:win
~~~

---

## 🚢 Automated Release (GitHub Actions)

Every tagged commit triggers an automated build pipeline:

~~~bash
git tag v1.7.0
git push origin v1.7.0
~~~

The workflow will:
1. ✅ Inject version into `pubspec.yaml` & `package.json`
2. 🤖 Build signed Android APK
3. 🪟 Build Windows installer with gradient sidebar
4. 📦 Generate installer artwork
5. 🚀 Publish to **GitHub Releases**

---

## 🎨 Theme System

SonicWave ships with **8 carefully crafted accent palettes**:

| Name | Hex |
|---|---|
| 💜 Purple | `#8B5CF6` |
| 💙 Blue | `#3B82F6` |
| 💗 Pink | `#EC4899` |
| ❤️ Red | `#EF4444` |
| 🧡 Orange | `#F97316` |
| 🟡 Gold | `#F59E0B` |
| 💚 Green | `#10B981` |
| 🩵 Teal | `#14B8A6` |

**Switch themes anytime** via **Settings → Appearance**. Dark and light modes remember their own accent color independently.

---

## 🏗️ Architecture

~~~
lib/
├── main.dart                  # App entry + AudioService init
├── models/
│   └── track.dart             # Hive-annotated Track model
├── services/
│   ├── player_service.dart    # Playback engine (just_audio)
│   ├── storage_service.dart   # Hive persistence layer
│   ├── update_service.dart    # GitHub Release checker
│   └── extra_services.dart    # Metadata + Lyrics
├── screens/
│   ├── player_screen.dart     # Full player UI
│   ├── library_screen.dart    # Library + Search + Tabs
│   └── settings_screen.dart   # Theme + About + Update
├── widgets/
│   ├── track_tile.dart        # List item with menu
│   ├── mini_player.dart       # Bottom bar player
│   └── update_dialog.dart     # Update prompt
├── theme/
│   └── app_theme.dart         # Theme system
└── utils/
    └── web_bridge.dart        # Electron ↔ Flutter IPC
~~~

### Key Technologies

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.24 |
| Audio Engine | [just_audio](https://pub.dev/packages/just_audio) |
| Background Playback | [audio_service](https://pub.dev/packages/audio_service) |
| Storage | [hive_flutter](https://pub.dev/packages/hive_flutter) |
| Metadata | [music-metadata](https://www.npmjs.com/package/music-metadata) |
| Lyrics | [LRCLIB API](https://lrclib.net) |
| Windows Runtime | Electron 22 |
| CI/CD | GitHub Actions |

---

## 👨 Author

<div align="center">

### **AnishtayiN**

[![Telegram](https://img.shields.io/badge/Telegram-@AnishrayiN-0088cc?style=for-the-badge&logo=telegram)](https://t.me/AnishrayiN)
[![GitHub](https://img.shields.io/badge/GitHub-AnishtayiN-181717?style=for-the-badge&logo=github)](https://github.com/AnishtayiN)

</div>

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

1. 🐛 Report bugs via [Issues](https://github.com/AnishtayiN/MusicPlayer/issues)
2. 💡 Suggest features
3. 🔧 Submit pull requests

---

## 📄 License

This project is released under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">

### ⭐ If you like SonicWave, consider giving it a star!

**Made with ❤️ and Flutter**

</div>
