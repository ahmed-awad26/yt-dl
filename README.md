# 📺 YT-Channel-Downloader for Termux

<div align="center">

![Version](https://img.shields.io/badge/version-2.0-blue)
![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Android-green)
![License](https://img.shields.io/badge/license-MIT-orange)
![yt-dlp](https://img.shields.io/badge/powered%20by-yt--dlp-red)

<br>

### 🌐 اختر لغتك / Choose Your Language

[![العربية](https://img.shields.io/badge/🇸🇦-العربية-green?style=for-the-badge)](#-النسخة-العربية)
&nbsp;&nbsp;
[![English](https://img.shields.io/badge/🇬🇧-English-blue?style=for-the-badge)](#-english-version)

</div>

---
---

# 🇸🇦 النسخة العربية

<div align="center">

**تحميل قنوات يوتيوب كاملة بضغطة واحدة — من داخل Termux على أندرويد**

[التثبيت](#-التثبيت-السريع) • [الاستخدام](#-الاستخدام) • [هيكل المجلدات](#-هيكل-المجلدات) • [استكشاف الأخطاء](#-استكشاف-الأخطاء)

</div>

---

## ✨ المميزات

| الميزة | التفاصيل |
|--------|----------|
| 📥 تحميل كامل للقناة | Playlists + Uploads + مقاطع غير مصنفة |
| ⏱ آخر تحديث فقط | تحميل المقاطع الجديدة منذ آخر تشغيل |
| 🎬 جودات متعددة | Best / 4K / 1080p / 720p / 480p / 360p |
| 🎵 صوت فقط | MP3 و M4A بجودة عالية |
| 📁 تنظيم ذكي | مجلد لكل قناة، مجلد فرعي لكل Playlist |
| 🖥 واجهة TUI | واجهة تفاعلية ملونة داخل Termux |
| 🔄 تحديث تلقائي | يثبت جميع المتطلبات تلقائياً |
| 📝 سجلات كاملة | ملف log لكل عملية تحميل |

---

## 📋 المتطلبات

- **Android** 7.0 أو أحدث
- **Termux** من F-Droid *(لا تستخدم إصدار Google Play — قديم)*
- اتصال بالإنترنت أثناء التثبيت
- مساحة كافية على التخزين

> ⚠️ **مهم:** قم بتثبيت Termux من [F-Droid](https://f-droid.org/en/packages/com.termux/) وليس من Google Play.

---

## 🚀 التثبيت السريع

### الطريقة 1: مباشرة (موصى بها)

```bash
# 1. استنسخ المشروع
pkg install git -y && git clone https://github.com/ahmed-awad26/ytdl-termux.git

# 2. ادخل للمجلد
cd ytdl-termux

# 3. شغّل المثبّت
bash install.sh
```

### الطريقة 2: يدوياً بدون Git

```bash
# تثبيت curl أولاً
pkg install curl -y

# تحميل المشروع مضغوط
curl -L https://github.com/ahmed-awad26/ytdl-termux/archive/main.zip -o ytdl.zip
unzip ytdl.zip
cd ytdl-termux-main
bash install.sh
```

---

## 📦 الحزم التي يثبتها `install.sh` تلقائياً

| الحزمة | السبب |
|--------|-------|
| `python` | تشغيل yt-dlp والمساعد |
| `ffmpeg` | دمج الفيديو والصوت وتحويل الصيغ |
| `curl` | تحميل الملفات |
| `wget` | تحميل بديل |
| `git` | تحديث البرنامج |
| `jq` | معالجة JSON |
| `openssl` | الاتصالات الآمنة |
| `termux-tools` | أدوات Termux الأساسية |
| `yt-dlp` *(pip)* | محرك التحميل الرئيسي |
| `requests` *(pip)* | طلبات HTTP |
| `tqdm` *(pip)* | شريط التقدم |
| `rich` *(pip)* | التنسيق الملون |

---

## 🎮 الاستخدام

### تشغيل البرنامج

```bash
# من مجلد المشروع
bash ytdl.sh

# أو من أي مكان (بعد التثبيت)
ytdl
```

### خطوات التحميل

```
1. اختر "تنزيل قناة يوتيوب" من القائمة الرئيسية
2. أدخل رابط القناة:
   • https://www.youtube.com/@ChannelName
   • https://www.youtube.com/channel/UCxxxxxxx
   • https://www.youtube.com/c/ChannelName
3. اختر الجودة (1080p موصى به)
4. اختر وضع التحميل
5. أكد البدء — يبدأ التحميل فوراً
```

### أوضاع التحميل

| الوضع | الوصف |
|-------|-------|
| Playlists فقط | تحمّل كل Playlists القناة منظمة في مجلدات |
| Uploads فقط | كل ما رُفع على القناة |
| Playlists + Uploads | الاثنان معاً |
| الكل + غير مصنفة | الاثنان + المقاطع خارج أي Playlist |
| آخر تحديث | فقط المقاطع الجديدة منذ آخر مرة شغّلت البرنامج |

---

## 📁 هيكل المجلدات

```
/sdcard/Download/YT-Channels/
│
├── 📁 ChannelName_1/
│   ├── 📁 Playlists/
│   │   ├── 📁 Playlist_Title_1/
│   │   │   ├── Video 1 [id].mp4
│   │   │   └── Video 2 [id].mp4
│   │   └── 📁 Playlist_Title_2/
│   │       └── ...
│   ├── 📁 Uploads/
│   │   └── All_Videos [id].mp4
│   ├── 📁 Uncategorized/
│   │   └── (مقاطع خارج أي Playlist)
│   ├── 📁 Latest/
│   │   └── (آخر تحديث)
│   ├── channel_metadata.json
│   └── download_20240101_1200.log
│
└── 📁 ChannelName_2/
    └── ...
```

---

## 🔧 استكشاف الأخطاء

### ❌ إذن التخزين مرفوض

```bash
# الحل 1: طلب الإذن يدوياً
termux-setup-storage

# الحل 2: في أندرويد 11+
# الإعدادات → التطبيقات → Termux → الأذونات → التخزين → السماح بالكل
```

### ❌ yt-dlp غير موجود

```bash
pip install yt-dlp
# أو
pip3 install yt-dlp
```

### ❌ ffmpeg غير موجود

```bash
pkg install ffmpeg -y
```

### ❌ التحميل بطيء أو يتوقف

```bash
bash update.sh
# أو
pip install --upgrade yt-dlp
```

### ❌ خطأ SSL / Certificate

```bash
pkg install openssl ca-certificates -y
pip install --upgrade certifi
```

### ❌ لا مساحة كافية

```bash
df -h /sdcard
find "$HOME/storage/shared/Download" -name "*.part" -delete
```

### ❌ خطأ في pkg update

```bash
termux-change-repo
pkg update -y
```

### ❌ البرنامج لا يجد Playlists

```bash
# بعض القنوات تخفي Playlists — جرب:
# https://www.youtube.com/@ChannelName/playlists
```

---

## 🔄 التحديث

```bash
cd ytdl-termux
bash update.sh
```

---

## ⚙️ الإعداد اليدوي

```bash
# عرض ملف الإعداد
cat .config

# تغيير مجلد التحميل
echo "DOWNLOAD_ROOT=/sdcard/MyVideos" >> .config
```

---

## 📄 الرخصة

MIT License — للاستخدام الشخصي.  
**تنبيه:** يرجى احترام حقوق الملكية الفكرية لمنشئي المحتوى.

---

## 🤝 المساهمة

```bash
git checkout -b feature/my-feature
git commit -m "feat: add new feature"
git push origin feature/my-feature
```

<div align="center">

صُنع بـ ❤️ لمجتمع Termux العربي  
⭐ إذا أعجبك المشروع، أضفه للمفضلة!

[⬆ العودة لاختيار اللغة](#-اختر-لغتك--choose-your-language)

</div>

---
---

# 🇬🇧 English Version

<div align="center">

**Download entire YouTube channels with a single command — inside Termux on Android**

[Installation](#-quick-installation) • [Usage](#-usage) • [Folder Structure](#-folder-structure) • [Troubleshooting](#-troubleshooting)

</div>

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 📥 Full channel download | Playlists + Uploads + Uncategorized videos |
| ⏱ Latest updates only | Download only new videos since last run |
| 🎬 Multiple qualities | Best / 4K / 1080p / 720p / 480p / 360p |
| 🎵 Audio only | High-quality MP3 and M4A extraction |
| 📁 Smart organization | One folder per channel, subfolders per playlist |
| 🖥 TUI Interface | Interactive colored menu inside Termux |
| 🔄 Auto-install | Automatically installs all dependencies |
| 📝 Full logging | Log file for every download session |

---

## 📋 Requirements

- **Android** 7.0 or later
- **Termux** from F-Droid *(do NOT use the Google Play version — it's outdated)*
- Internet connection during installation
- Sufficient storage space

> ⚠️ **Important:** Install Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/), not Google Play.

---

## 🚀 Quick Installation

### Method 1: Via Git (Recommended)

```bash
# 1. Clone the project
pkg install git -y && git clone https://github.com/ahmed-awad26/ytdl-termux.git

# 2. Enter the folder
cd ytdl-termux

# 3. Run the installer
bash install.sh
```

### Method 2: Manual (without Git)

```bash
# Install curl first
pkg install curl -y

# Download as ZIP
curl -L https://github.com/YOUR_USERNAME/ytdl-termux/archive/main.zip -o ytdl.zip
unzip ytdl.zip
cd ytdl-termux-main
bash install.sh
```

---

## 📦 Packages Installed Automatically by `install.sh`

| Package | Purpose |
|---------|---------|
| `python` | Runs yt-dlp and the helper script |
| `ffmpeg` | Merges video/audio and converts formats |
| `curl` | File downloading |
| `wget` | Fallback downloader |
| `git` | Project updates |
| `jq` | JSON processing |
| `openssl` | Secure connections |
| `termux-tools` | Core Termux utilities |
| `yt-dlp` *(pip)* | Main download engine |
| `requests` *(pip)* | HTTP requests |
| `tqdm` *(pip)* | Progress bars |
| `rich` *(pip)* | Colored terminal output |

---

## 🎮 Usage

### Run the Program

```bash
# From the project folder
bash ytdl.sh

# Or from anywhere after installation
ytdl
```

### Download Steps

```
1. Select "Download YouTube Channel" from the main menu
2. Enter the channel URL:
   • https://www.youtube.com/@ChannelName
   • https://www.youtube.com/channel/UCxxxxxxx
   • https://www.youtube.com/c/ChannelName
3. Choose your quality (1080p recommended)
4. Choose download mode
5. Confirm — download starts immediately
```

### Download Modes

| Mode | Description |
|------|-------------|
| Playlists only | Downloads all channel playlists into separate folders |
| Uploads only | Every video ever uploaded to the channel |
| Playlists + Uploads | Both combined |
| All + Uncategorized | Everything plus videos not in any playlist |
| Latest update | Only new videos since the last time you ran the script |

---

## 📁 Folder Structure

```
/sdcard/Download/YT-Channels/
│
├── 📁 ChannelName_1/
│   ├── 📁 Playlists/
│   │   ├── 📁 Playlist_Title_1/
│   │   │   ├── Video 1 [id].mp4
│   │   │   └── Video 2 [id].mp4
│   │   └── 📁 Playlist_Title_2/
│   │       └── ...
│   ├── 📁 Uploads/
│   │   └── All_Videos [id].mp4
│   ├── 📁 Uncategorized/
│   │   └── (videos outside any playlist)
│   ├── 📁 Latest/
│   │   └── (most recent update)
│   ├── channel_metadata.json
│   └── download_20240101_1200.log
│
└── 📁 ChannelName_2/
    └── ...
```

---

## 🔧 Troubleshooting

### ❌ Storage permission denied

```bash
# Solution 1: Request permission manually
termux-setup-storage

# Solution 2: On Android 11+
# Settings → Apps → Termux → Permissions → Storage → Allow all
```

### ❌ yt-dlp not found

```bash
pip install yt-dlp
# or
pip3 install yt-dlp
```

### ❌ ffmpeg not found

```bash
pkg install ffmpeg -y
```

### ❌ Download is slow or stalls

```bash
# Update yt-dlp to the latest version
bash update.sh
# or
pip install --upgrade yt-dlp
```

### ❌ SSL / Certificate error

```bash
pkg install openssl ca-certificates -y
pip install --upgrade certifi
```

### ❌ No space left on device

```bash
# Check available space
df -h /sdcard
# Remove incomplete .part files
find "$HOME/storage/shared/Download" -name "*.part" -delete
```

### ❌ pkg update fails

```bash
# Switch mirror
termux-change-repo
# Then retry
pkg update -y
```

### ❌ No playlists found

```bash
# Some channels hide playlists — try this URL directly:
# https://www.youtube.com/@ChannelName/playlists
```

---

## 🔄 Updating

```bash
cd ytdl-termux
bash update.sh
```

---

## ⚙️ Manual Configuration

```bash
# View config file
cat .config

# Change download folder
echo "DOWNLOAD_ROOT=/sdcard/MyVideos" >> .config
```

---

## 📄 License

MIT License — free for personal use.  
**Notice:** Please respect the intellectual property rights of content creators.

---

## 🤝 Contributing

```bash
git checkout -b feature/my-feature
git commit -m "feat: add new feature"
git push origin feature/my-feature
```

<div align="center">

Made with ❤️ for the Termux community  
⭐ If you find this useful, give it a star!

[⬆ Back to language selection](#-اختر-لغتك--choose-your-language)

</div>
