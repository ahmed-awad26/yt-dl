#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   ytdl.sh -- Main Runner with Full TUI
# ============================================================

# ── Colors & styles ─────────────────────────────────────────
RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
CYAN='\033[0;36m';   BLUE='\033[0;34m';  MAGENTA='\033[0;35m'
WHITE='\033[1;37m';  RESET='\033[0m';    BOLD='\033[1m'
DIM='\033[2m'

# ── Load config ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/.config"

if [ -f "$CONFIG" ]; then
  source "$CONFIG"
else
  for dir in "$HOME/storage/shared" "/sdcard" "/storage/emulated/0"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
      SDCARD="$dir"; break
    fi
  done
  SDCARD="${SDCARD:-$HOME/downloads}"
  DOWNLOAD_ROOT="$SDCARD/Download/YT-Channels"
fi

mkdir -p "$DOWNLOAD_ROOT"

# ── Helpers ──────────────────────────────────────────────────
clear_screen() { clear; }

draw_box() {
  local title="$1"
  local width=52
  local pad=$(( (width - ${#title} - 2) / 2 ))
  printf "\033[0;36m\033[1m\n"
  printf "  +"; printf -- '-%.0s' $(seq 1 $width); printf "+\n"
  printf "  |%${pad}s\033[1;37m%s\033[0;36m%${pad}s  |\n" "" "$title" ""
  printf "  +"; printf -- '-%.0s' $(seq 1 $width); printf "+\n"
  printf "\033[0m\n"
}

divider() {
  printf "  \033[2m\033[36m------------------------------------------------------\033[0m\n"
}

menu_item() {
  local num="$1"; local icon="$2"; local text="$3"; local desc="$4"
  printf "  \033[36m[\033[1;37m%s\033[0;36m]\033[0m %s \033[1;37m%s\033[0m  \033[2m%s\033[0m\n"     "$num" "$icon" "$text" "$desc"
}

# ── Main banner ──────────────────────────────────────────────
show_main_banner() {
  clear_screen
  printf "\033[0;36m"
  printf "  +------------------------------------------------------+\n"
  printf "  |                                                      |\n"
  printf "  |   \033[1;37m █████╗ ██╗    ██╗\033[0;36m                               |\n"
  printf "  |   \033[1;37m██╔══██╗██║    ██║\033[0;36m                               |\n"
  printf "  |   \033[1;37m███████║██║ █╗ ██║\033[0;36m                               |\n"
  printf "  |   \033[1;37m██╔══██║██║███╗██║\033[0;36m                               |\n"
  printf "  |   \033[1;37m██║  ██║╚███╔███╔╝\033[0;36m                               |\n"
  printf "  |   \033[1;37m╚═╝  ╚═╝ ╚══╝╚══╝\033[0;36m                               |\n"
  printf "  |                                                      |\n"
  printf "  |      \033[1;37mYT Downloader\033[0;36m  \033[2;37mv2.0 -- Termux\033[0;36m              |\n"
  printf "  |                                                      |\n"
  printf "  +------------------------------------------------------+\n"
  printf "\033[0m\n"
  printf "  \033[2mDownload dir: \033[0;36m%s\033[0m\n" "$DOWNLOAD_ROOT"
  printf "  \033[2mTime: %s\033[0m\n" "$(date '+%Y-%m-%d %H:%M')"
  printf "\n"
}

# ── Quality selector ─────────────────────────────────────────
select_quality() {
  clear_screen
  draw_box "Select Video Quality"
  echo ""
  menu_item "1" ">>>" "Best Quality (Auto)"  "Picks best video + audio automatically"
  menu_item "2" "[4K]" "4K / 2160p"          "Ultra HD -- very large files"
  menu_item "3" "[HD]" "1080p Full HD"        "Excellent quality -- recommended"
  menu_item "4" "[HD]" "720p HD"              "High quality -- medium size"
  menu_item "5" "[SD]" "480p"                "Medium quality -- good for mobile"
  menu_item "6" "[LQ]" "360p"                "Low quality -- smallest size"
  menu_item "7" "[MP3]" "Audio only MP3"     "Extract audio in high quality"
  menu_item "8" "[M4A]" "Audio only M4A"     "Extract audio as M4A"
  echo ""
  divider
  printf "  \033[36mChoose [1-8]:\033[0m "
  read -r quality_choice

  case "$quality_choice" in
    1) FORMAT="bestvideo+bestaudio/best"; EXT="mp4"; QUALITY_NAME="Best" ;;
    2) FORMAT="bestvideo[height<=2160]+bestaudio/best[height<=2160]"; EXT="mp4"; QUALITY_NAME="4K" ;;
    3) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; EXT="mp4"; QUALITY_NAME="1080p" ;;
    4) FORMAT="bestvideo[height<=720]+bestaudio/best[height<=720]"; EXT="mp4"; QUALITY_NAME="720p" ;;
    5) FORMAT="bestvideo[height<=480]+bestaudio/best[height<=480]"; EXT="mp4"; QUALITY_NAME="480p" ;;
    6) FORMAT="bestvideo[height<=360]+bestaudio/best[height<=360]"; EXT="mp4"; QUALITY_NAME="360p" ;;
    7) FORMAT="bestaudio/best"; EXT="mp3"; QUALITY_NAME="MP3 Audio"; AUDIO_ONLY=true ;;
    8) FORMAT="bestaudio/best"; EXT="m4a"; QUALITY_NAME="M4A Audio"; AUDIO_ONLY=true ;;
    *) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]"; EXT="mp4"; QUALITY_NAME="1080p (default)" ;;
  esac

  ok_msg "[OK] Quality selected: $QUALITY_NAME"
}

ok_msg()   { printf "  \033[32m%s\033[0m\n" "$1"; sleep 1; }
err_msg()  { printf "  \033[31m[ERR] %s\033[0m\n" "$1"; }
warn_msg() { printf "  \033[33m[!!] %s\033[0m\n" "$1"; sleep 1; }

# ── Mode selector ─────────────────────────────────────────────
select_mode() {
  clear_screen
  draw_box "Select Download Mode"
  echo ""
  menu_item "1" "[PL]"  "Playlists only"           "Download named playlists only"
  menu_item "2" "[UP]"  "Uploads only"             "All channel videos (flat)"
  menu_item "3" "[ALL]" "Playlists + Uploads"      "Both playlists and all uploads"
  menu_item "4" "[+U]"  "All + Uncategorized"      "Playlists + uploads not in any playlist"
  menu_item "5" "[NEW]" "Latest since last run"    "Only new videos since last download"
  echo ""
  divider
  printf "  \033[36mChoose [1-5]:\033[0m "
  read -r mode_choice

  case "$mode_choice" in
    1) DL_MODE="playlists";         MODE_NAME="Playlists only" ;;
    2) DL_MODE="uploads";           MODE_NAME="Uploads only" ;;
    3) DL_MODE="all";               MODE_NAME="Playlists + Uploads" ;;
    4) DL_MODE="all_uncategorized"; MODE_NAME="All + Uncategorized" ;;
    5) DL_MODE="latest";            MODE_NAME="Latest since last run" ;;
    *) DL_MODE="all";               MODE_NAME="All (default)" ;;
  esac

  ok_msg "[OK] Mode: $MODE_NAME"
}

# ── URL normalizer ───────────────────────────────────────────
# Accepts ANY YouTube channel URL format and returns a clean canonical URL
normalize_channel_url() {
  local raw="$1"
  local clean=""

  # Step 1: strip leading/trailing whitespace
  raw=$(echo "$raw" | tr -d '[:space:]')

  # Step 2: add https:// if missing
  if [[ "$raw" != http* ]]; then
    raw="https://$raw"
  fi

  # Step 3: normalize domain variants
  # youtube.com (no www) -> www.youtube.com
  raw=$(echo "$raw" | sed 's|https://youtube\.com|https://www.youtube.com|g')
  # m.youtube.com -> www.youtube.com  (mobile)
  raw=$(echo "$raw" | sed 's|https://m\.youtube\.com|https://www.youtube.com|g')
  # music.youtube.com -> www.youtube.com
  raw=$(echo "$raw" | sed 's|https://music\.youtube\.com|https://www.youtube.com|g')

  # Step 4: strip ALL query params (?si= ?feature= ?app= ?sub= etc.)
  raw=$(echo "$raw" | sed 's/?.*//')

  # Step 5: strip trailing slash
  raw=$(echo "$raw" | sed 's|/$||')

  # Step 6: detect pattern and build clean URL
  # Pattern: /@handle  (most common modern format)
  if echo "$raw" | grep -qE '/@[^/]+'; then
    handle=$(echo "$raw" | grep -oE '/@[^/]+' | head -1)
    clean="https://www.youtube.com${handle}"

  # Pattern: /channel/UCxxxxxx
  elif echo "$raw" | grep -qE '/channel/UC[a-zA-Z0-9_-]+'; then
    channel_id=$(echo "$raw" | grep -oE '/channel/UC[a-zA-Z0-9_-]+' | head -1)
    clean="https://www.youtube.com${channel_id}"

  # Pattern: /c/CustomName
  elif echo "$raw" | grep -qE '/c/[^/]+'; then
    cname=$(echo "$raw" | grep -oE '/c/[^/]+' | head -1)
    clean="https://www.youtube.com${cname}"

  # Pattern: /user/Username
  elif echo "$raw" | grep -qE '/user/[^/]+'; then
    uname=$(echo "$raw" | grep -oE '/user/[^/]+' | head -1)
    clean="https://www.youtube.com${uname}"

  # Pattern: already a full valid youtube.com URL
  elif echo "$raw" | grep -qE 'https://www\.youtube\.com'; then
    clean="$raw"

  else
    # Unknown format — pass as-is and let yt-dlp try
    clean="$raw"
  fi

  echo "$clean"
}

# ── Channel URL input ────────────────────────────────────────
get_channel_url() {
  clear_screen
  draw_box "Channel URL"
  echo ""
  printf "  \033[1;37mPaste any YouTube channel link -- all formats accepted:\033[0m\n"
  printf "  \033[2m  https://youtube.com/@Name?si=xxxxx     (share link)\033[0m\n"
  printf "  \033[2m  https://www.youtube.com/@Name          (handle)\033[0m\n"
  printf "  \033[2m  https://www.youtube.com/channel/UCxxx  (channel ID)\033[0m\n"
  printf "  \033[2m  https://www.youtube.com/c/Name         (custom URL)\033[0m\n"
  printf "  \033[2m  https://www.youtube.com/user/Name      (legacy user)\033[0m\n"
  printf "  \033[2m  https://m.youtube.com/@Name            (mobile)\033[0m\n"
  echo ""
  divider
  printf "  \033[36mEnter channel URL:\033[0m "
  read -r RAW_URL

  if [[ -z "$RAW_URL" ]]; then
    err_msg "URL is empty! Please try again."
    sleep 1
    get_channel_url
    return
  fi

  # Normalize the URL immediately (no network calls here)
  CHANNEL_URL=$(normalize_channel_url "$RAW_URL")
  printf "  \033[2mNormalized: \033[36m%s\033[0m\n" "$CHANNEL_URL"

  # Extract channel name from URL only (no network calls)
  CHANNEL_NAME=""
  if echo "$CHANNEL_URL" | grep -qE '/@'; then
    CHANNEL_NAME=$(echo "$CHANNEL_URL" | grep -oE '@[^/]+' | tr -d '@')
  elif echo "$CHANNEL_URL" | grep -qE '/channel/'; then
    CHANNEL_NAME=$(echo "$CHANNEL_URL" | grep -oE 'UC[a-zA-Z0-9_-]+' | head -1)
  elif echo "$CHANNEL_URL" | grep -qE '/c/|/user/'; then
    CHANNEL_NAME=$(echo "$CHANNEL_URL" | sed 's|.*/||')
  fi

  if [[ -z "$CHANNEL_NAME" ]]; then
    CHANNEL_NAME="Channel_$(date +%s)"
  fi

  ok_msg "[OK] URL accepted: $CHANNEL_NAME"

  CHANNEL_SAFE=$(echo "$CHANNEL_NAME" | tr -dc 'a-zA-Z0-9_\- ' | tr ' ' '_')
  CHANNEL_DIR="$DOWNLOAD_ROOT/$CHANNEL_SAFE"
  mkdir -p "$CHANNEL_DIR"
}

# ── Resolve real channel name (called only before download) ──
# ── Confirm summary ──────────────────────────────────────────
confirm_download() {
  clear_screen
  draw_box "Download Summary"
  echo ""
  printf "  \033[1;37mChannel:\033[0m      \033[0;36m%s\033[0m\n" "$CHANNEL_NAME"
  printf "  \033[1;37mURL:\033[0m          \033[2m%s\033[0m\n" "$CHANNEL_URL"
  printf "  \033[1;37mQuality:\033[0m      \033[0;32m%s\033[0m\n" "$QUALITY_NAME"
  printf "  \033[1;37mMode:\033[0m         \033[1;33m%s\033[0m\n" "$MODE_NAME"
  printf "  \033[1;37mSave to:\033[0m      \033[0;35m%s\033[0m\n" "$CHANNEL_DIR"
  printf "\n"
  divider
  printf "  \033[36m[Y]\033[0m Start download   \033[31m[N]\033[0m Cancel\n"
  printf "\n"
  printf "  Choose: "
  read -r confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    printf "  \033[33mCancelled.\033[0m\n"
    main_menu
    return
  fi

}

# ── Live progress display ────────────────────────────────────
show_download_ui() {
  clear_screen
  printf "\033[0;36m"
  printf "  +------------------------------------------------------+\n"
  printf "  |   \033[1;37mDownloading...\033[0;36m                                    |\n"
  printf "  +------------------------------------------------------+\n"
  printf "\033[0m\n"
  printf "  \033[1;37mChannel:\033[0m \033[0;36m%s\033[0m\n" "$CHANNEL_NAME"
  printf "  \033[1;37mMode:\033[0m    \033[1;33m%s\033[0m\n" "$MODE_NAME"
  printf "  \033[1;37mQuality:\033[0m \033[0;32m%s\033[0m\n" "$QUALITY_NAME"
  printf "\n"
  divider
  printf "\n"
}

# ── Draw progress bar ────────────────────────────────────────
# Usage: draw_progress <percent 0-100> <speed> <size>
draw_progress() {
  local pct="${1:-0}"
  local speed="${2:---}"
  local size="${3:---}"
  local bar_width=30
  local filled=$(( pct * bar_width / 100 ))
  local empty=$(( bar_width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  # \r  = go to start of line
  # \033[K = erase rest of line (prevents leftover chars from longer previous update)
  printf "\r\033[K  \033[36m[\033[32m%s\033[36m]\033[0m \033[1m%3d%%\033[0m  \033[2m%-12s  %-8s\033[0m" \
    "$bar" "$pct" "$speed" "$size"
}

# ── Parse yt-dlp output and show live progress ───────────────
# Usage: stream_with_progress <log_file> [report_file]
stream_with_progress() {
  local log_file="$1"
  local report_file="${2:-}"   # optional: path to report .txt
  local current_title=""
  local current_path=""
  local last_title=""
  local vid_done=0
  local vid_skip=0

  while IFS= read -r line; do
    # Log everything
    echo "$line" >> "$log_file"

    # ── New video title ──────────────────────────────────────
    # [download] Destination: .../Title [id].mp4
    if echo "$line" | grep -qE '^\[download\] Destination:'; then
      # Full path for report
      current_path=$(echo "$line" | sed 's/.*Destination: //')
      # Strip path+ext for display title
      current_title=$(printf '%s' "$current_path" | sed 's|.*/||' \
        | sed 's/ \[.*$//' | sed 's/\.f[0-9]\+\.[a-z0-9]\+$//' | sed 's/\.[a-z0-9]\{2,4\}$//')
      # Only print title on first stream (video part), skip audio part re-print
      if [[ -n "$current_title" && "$current_title" != "$last_title" ]]; then
        last_title="$current_title"
        local short_title="${current_title:0:50}"
        [ ${#current_title} -gt 50 ] && short_title="${current_title:0:47}..."
        printf "\n  \033[35m▶ \033[1;37m%s\033[0m\n" "${short_title}"
      fi
      draw_progress 0 "" ""

    # ── Already downloaded ───────────────────────────────────
    elif echo "$line" | grep -qE '^\[download\].*has already been downloaded'; then
      vid_skip=$(( vid_skip + 1 ))
      local short_title
      short_title=$(echo "$line" | sed 's/\[download\] //' | sed 's/ has already.*//' | sed 's|.*/||')
      short_title="${short_title:0:46}"
      printf "\n  \033[2m[skip] %s\033[0m\n" "$short_title"

    # ── Progress percentage line ─────────────────────────────
    # [download]  75.3% of  123.45MiB at    2.50MiB/s ETA 00:12
    elif echo "$line" | grep -qE '^\[download\]\s+[0-9]+\.[0-9]+%'; then
      local pct speed size
      pct=$(echo "$line"  | grep -oE '[0-9]+\.[0-9]+%' | head -1 | tr -d '%' | cut -d. -f1)
      speed=$(echo "$line" | grep -oE 'at\s+[0-9.]+[KMG]iB/s' | sed 's/at //' | head -1)
      size=$(echo "$line"  | grep -oE 'of\s+[~]?[0-9.]+[KMG]iB' | sed 's/of //' | head -1)
      draw_progress "${pct:-0}" "${speed:---}" "${size:---}"

    # ── 100% / file finished ─────────────────────────────────
    # Only count when it says "100% of X in HH:MM:SS" = truly finished
    elif echo "$line" | grep -qE '^\[download\] 100(\.0)?% of .* in [0-9]'; then
      draw_progress 100 "" ""
      vid_done=$(( vid_done + 1 ))
      printf "\n  \033[32m✔ Done  [videos: %d  skipped: %d]\033[0m\n" "$vid_done" "$vid_skip"
      # Write to report file if provided
      if [[ -n "$report_file" && -n "$current_path" ]]; then
        printf "%s\n" "$current_path" >> "${report_file}.tmp"
      fi
    elif echo "$line" | grep -qE '^\[download\] 100%'; then
      draw_progress 100 "" ""

    # ── ffmpeg merging ───────────────────────────────────────
    elif echo "$line" | grep -qE '^\[ffmpeg\]|^\[Merger\]'; then
      printf "\r  \033[1;33m⚙ Merging...\033[0m                                          "

    # ── Errors ───────────────────────────────────────────────
    elif echo "$line" | grep -qE '^ERROR'; then
      # Suppress ffmpeg postprocessing error (cosmetic - file still downloaded)
      if echo "$line" | grep -qE 'ffmpeg not found|Postprocessing'; then
        : # suppress - file downloads fine without ffmpeg
      else
        printf "\n  \033[0;31m[ERR] %s\033[0m\n" "$line"
      fi

    # ── Warnings (suppress noisy but harmless ones) ──────────
    elif echo "$line" | grep -qE '^WARNING'; then
      # Skip cosmetic/harmless warnings
      if echo "$line" | grep -qE 'No supported JavaScript runtime|merging of multiple formats|unavailable video is hidden'; then
        : # suppress
      else
        printf "  \033[1;33m[!!] %s\033[0m\n" "$line"
      fi
    fi

  done
  printf "\n  \033[2mTotal downloaded: \033[32m%d\033[2m  |  Skipped: \033[33m%d\033[0m\n" "$vid_done" "$vid_skip"
}

# ── Check archive for videos whose files are missing on disk ─────────────────
# If missing files found → ask user: re-download or keep skipping
check_missing_from_archive() {
  local archive="$1"
  local dir="$2"
  [ -f "$archive" ] || return   # no archive yet → first run, skip check

  local missing=()
  local missing_ids=()

  while IFS= read -r entry; do
    # Archive format: "youtube VIDEO_ID"
    local vid_id
    vid_id=$(echo "$entry" | awk '{print $2}')
    [[ -z "$vid_id" ]] && continue

    # Check if any file in dir contains this ID
    if ! find "$dir" -maxdepth 1 -name "*${vid_id}*" | grep -q .; then
      missing+=("$vid_id")
    fi
  done < "$archive"

  [ ${#missing[@]} -eq 0 ] && return   # all files present, nothing to do

  printf "
  [1;33m⚠  %d فيديو موجود في السجل لكن ملفه مش موجود:[0m
" "${#missing[@]}"
  for id in "${missing[@]}"; do
    printf "  [2m  - %s[0m
" "$id"
  done
  printf "
"
  printf "  [36m[1][0m إعادة تحميل الفيديوهات المفقودة
"
  printf "  [36m[2][0m تجاهل والمتابعة (skip زي ما هو)
"
  printf "
  اختار [1/2]: "
  read -r miss_choice

  if [[ "$miss_choice" == "1" ]]; then
    # Remove missing IDs from archive so yt-dlp re-downloads them
    for id in "${missing[@]}"; do
      sed -i "/youtube $id/d" "$archive" 2>/dev/null
    done
    printf "  [32m✓ تم حذف السجل للفيديوهات المفقودة — هيتعاد تحميلها[0m

"
  else
    printf "  [2mمتابعة مع السكيب...[0m

"
  fi
}

# ── Run yt-dlp safely (args as real array, never split by shell) ─────────────
# Usage: run_ytdlp <log_file> <url> [extra_flag extra_flag ...]
# Set REPORT_FILE before calling to enable per-session report
run_ytdlp() {
  local log_file="$1"; shift
  local url="$1";      shift
  # remaining $@ = optional extra flags

  local out_tmpl
  if [ "$AUDIO_ONLY" = true ]; then
    out_tmpl="${CURRENT_OUT_DIR}/%(title)s.%(ext)s"
  else
    out_tmpl="${CURRENT_OUT_DIR}/%(title)s [%(id)s].%(ext)s"
  fi

  # Archive file tracks completed videos → enables auto-resume after crash/disconnect
  local archive_file="${CURRENT_OUT_DIR}/.ytdl_archive"

  # ── Smart archive: check if archived videos still exist on disk ─
  check_missing_from_archive "$archive_file" "$CURRENT_OUT_DIR"

  local args=(
    "--ignore-errors"
    "--no-abort-on-error"
    "--continue"
    "--download-archive" "$archive_file"
    "--retries" "10"
    "--fragment-retries" "20"
    "--retry-sleep" "5"
    "--concurrent-fragments" "4"
    "--merge-output-format" "mp4"
    "--add-metadata"
    "--newline"
    "-o" "$out_tmpl"
  )

  if [ "$AUDIO_ONLY" = true ]; then
    args+=("-x" "--audio-format" "$EXT" "--audio-quality" "0")
  else
    args+=("-f" "$FORMAT")
  fi

  # Append any extra flags passed in
  for flag in "$@"; do
    args+=("$flag")
  done

  args+=("$url")

  yt-dlp "${args[@]}" 2>&1 | stream_with_progress "$log_file" "${REPORT_FILE:-}"

  # ── Cleanup: delete thumbnails, JSON, description files ─────
  cleanup_junk "$CURRENT_OUT_DIR"
}

# ── Delete non-video files left by yt-dlp ────────────────────
cleanup_junk() {
  local dir="$1"
  [ -d "$dir" ] || return
  # Delete: .webp .jpg .jpeg .png (thumbnails) .json .description .part (incomplete)
  find "$dir" -maxdepth 1 -type f     \( -name "*.webp" -o -name "*.jpg" -o -name "*.jpeg"     -o -name "*.png"  -o -name "*.json" -o -name "*.description"     -o -name "*.part" \) -delete 2>/dev/null
}

# ── Run download ─────────────────────────────────────────────
run_download() {
  local LOG="$CHANNEL_DIR/download_$(date +%Y%m%d_%H%M%S).log"
  AUDIO_ONLY=${AUDIO_ONLY:-false}

  show_download_ui

  case "$DL_MODE" in
    "uploads")
      printf "  \033[36m◆ Uploads\033[0m\n\n"
      CURRENT_OUT_DIR="$CHANNEL_DIR/Uploads"
      mkdir -p "$CURRENT_OUT_DIR"
      run_ytdlp "$LOG" "$CHANNEL_URL/videos"
      ;;

    "playlists")
      printf "  \033[36m◆ Playlists\033[0m\n\n"
      download_playlists "$LOG"
      ;;

    "all"|"all_uncategorized")
      printf "  \033[36m◆ Playlists\033[0m\n\n"
      download_playlists "$LOG"
      printf "\n  \033[36m◆ Uploads\033[0m\n\n"
      CURRENT_OUT_DIR="$CHANNEL_DIR/Uploads"
      mkdir -p "$CURRENT_OUT_DIR"
      run_ytdlp "$LOG" "$CHANNEL_URL/videos"

      if [ "$DL_MODE" = "all_uncategorized" ]; then
        printf "\n  \033[36m◆ Uncategorized (not in any playlist)\033[0m\n\n"
        # Build list of all playlist video IDs to skip
        local PLAYLIST_IDS
        PLAYLIST_IDS=$(yt-dlp --flat-playlist --no-warnings \
          --print "%(id)s" "$CHANNEL_URL/playlists" 2>/dev/null | sort -u)
        # Download all uploads, but skip videos that appear in playlists
        CURRENT_OUT_DIR="$CHANNEL_DIR/Uncategorized"
        mkdir -p "$CURRENT_OUT_DIR"
        if [[ -n "$PLAYLIST_IDS" ]]; then
          # Write playlist video IDs to archive file so yt-dlp skips them
          local SKIP_ARCHIVE="$CHANNEL_DIR/.playlist_archive"
          printf "%s\n" $PLAYLIST_IDS | sed 's/^/youtube /' > "$SKIP_ARCHIVE"
          run_ytdlp "$LOG" "$CHANNEL_URL/videos" "--download-archive" "$SKIP_ARCHIVE"
        else
          run_ytdlp "$LOG" "$CHANNEL_URL/videos"
        fi
      fi
      ;;

    "latest")
      printf "  \033[36m◆ Latest videos\033[0m\n\n"
      local DATEFILE="$CHANNEL_DIR/.last_run"
      local DATE_AFTER=""
      if [ -f "$DATEFILE" ]; then
        DATE_AFTER=$(cat "$DATEFILE")
        printf "  \033[2mLast run: %s\033[0m\n" "$DATE_AFTER"
      fi
      CURRENT_OUT_DIR="$CHANNEL_DIR/Latest"
      mkdir -p "$CURRENT_OUT_DIR"

      # Set report file — stream_with_progress writes new downloads to .tmp
      local RUN_DATE
      RUN_DATE=$(date '+%Y-%m-%d %H:%M')
      REPORT_FILE="$CHANNEL_DIR/latest_report.txt"
      export REPORT_FILE

      if [ -n "$DATE_AFTER" ]; then
        run_ytdlp "$LOG" "$CHANNEL_URL/videos" "--dateafter" "$DATE_AFTER"
      else
        run_ytdlp "$LOG" "$CHANNEL_URL/videos"
      fi

      # Build new section header + downloaded paths, prepend to report
      if [ -f "${REPORT_FILE}.tmp" ]; then
        local new_count
        new_count=$(wc -l < "${REPORT_FILE}.tmp")
        {
          printf "══════════════════════════════════════════════════════\n"
          printf "  📥 تحديث: %s\n" "$RUN_DATE"
          printf "  📺 عدد الفيديوهات الجديدة: %d\n" "$new_count"
          printf "══════════════════════════════════════════════════════\n"
          while IFS= read -r fpath; do
            # Get just filename without extension for display
            local fname
            fname=$(basename "$fpath" | sed 's/\.[^.]*$//' | sed 's/ \[.*$//')
            printf "  ▶ %s\n" "$fname"
            printf "    📂 %s\n" "$fpath"
            printf "\n"
          done < "${REPORT_FILE}.tmp"
          printf "\n"
          # Append old content if exists
          [ -f "$REPORT_FILE" ] && cat "$REPORT_FILE"
        } > "${REPORT_FILE}.new"
        mv "${REPORT_FILE}.new" "$REPORT_FILE"
        rm -f "${REPORT_FILE}.tmp"
        printf "\n  \033[32m📄 Report saved:\033[0m \033[2m%s\033[0m\n" "$REPORT_FILE"
      else
        printf "\n  \033[2mNo new videos downloaded in this session.\033[0m\n"
      fi

      date +%Y%m%d > "$DATEFILE"
      unset REPORT_FILE
      ;;
  esac

  echo ""
  divider
  show_completion "$LOG"
}

# ── Download playlists ────────────────────────────────────────
download_playlists() {
  local LOG="${1:-/dev/null}"
  printf "  \033[2mFetching playlist list...\033[0m\n"

  # Fetch playlist IDs and titles in two separate calls (avoids tab/separator issues)
  local PL_IDS PL_TITLES
  PL_IDS=$(yt-dlp --flat-playlist --no-warnings     --print "%(id)s"     "$CHANNEL_URL/playlists" 2>/dev/null | grep "^PL")
  PL_TITLES=$(yt-dlp --flat-playlist --no-warnings     --print "%(title)s"     "$CHANNEL_URL/playlists" 2>/dev/null | grep -v "^$")

  if [[ -z "$PL_IDS" ]]; then
    warn_msg "No playlists found for this channel."
    return
  fi

  # Combine IDs and titles using paste with real tab separator
  local PLAYLISTS
  PLAYLISTS=$(paste <(echo "$PL_IDS") <(echo "$PL_TITLES") | awk -F$'\t' '!seen[$1]++')

  local count=0
  while IFS=$'\t' read -r pl_id pl_title; do
    [[ -z "$pl_id" || "$pl_id" != PL* ]] && continue
    count=$((count+1))

    # Keep full UTF-8 title — only strip filesystem-unsafe chars
    local safe_title
    safe_title=$(printf '%s' "$pl_title"       | sed 's|[/\\:*?"<>|]|_|g'       | sed 's/^\.//'       | sed 's/[[:space:]]*$//')
    safe_title="${safe_title:-Playlist_$count}"

    CURRENT_OUT_DIR="$CHANNEL_DIR/Playlists/$safe_title"
    mkdir -p "$CURRENT_OUT_DIR"

    printf "\n  \033[35m[Playlist %d]\033[0m \033[1;37m%s\033[0m\n" "$count" "$pl_title"
    printf "  \033[2m→ %s\033[0m\n\n" "$CURRENT_OUT_DIR"

    run_ytdlp "$LOG" "https://www.youtube.com/playlist?list=${pl_id}"
  done <<< "$PLAYLISTS"

  if [[ $count -eq 0 ]]; then
    warn_msg "No valid playlists found (no PLxxxx IDs returned)."
  fi
}

# ── Completion screen ─────────────────────────────────────────
show_completion() {
  local log="$1"
  local errors=0
  [ -f "$log" ] && errors=$(grep -c "ERROR" "$log" 2>/dev/null || echo 0)
  local total=0
  [ -f "$log" ] && total=$(grep -c "\[download\]" "$log" 2>/dev/null || echo 0)

  clear_screen
  printf "\033[32m\033[1m"
  printf "  +------------------------------------------------------+\n"
  printf "  |                                                      |\n"
  printf "  |   Download complete!                                 |\n"
  printf "  |                                                      |\n"
  printf "  +------------------------------------------------------+\n"
  printf "\033[0m\n"
  printf "  \033[1;37mChannel:\033[0m          \033[0;36m%s\033[0m\n" "$CHANNEL_NAME"
  printf "  \033[1;37mSaved to:\033[0m         \033[0;35m%s\033[0m\n" "$CHANNEL_DIR"
  printf "  \033[1;37mDownload ops:\033[0m     \033[0;32m%s\033[0m\n" "$total"
  [ "$errors" -gt 0 ] && \
    printf "  \033[1;37mErrors:\033[0m           \033[0;31m%s\033[0m (check the log file)\n" "$errors"
  printf "  \033[1;37mLog file:\033[0m         \033[2m%s\033[0m\n" "$log"
  printf "\n"
  divider
  printf "\n"
  printf "  \033[36m[1]\033[0m Download another channel   \033[36m[2]\033[0m Exit\n"
  printf "\n"
  printf "  Choose: "
  read -r next_action

  case "$next_action" in
    1) main_menu ;;
    *) goodbye ;;
  esac
}

# ── Goodbye ──────────────────────────────────────────────────
goodbye() {
  clear_screen
  printf "\033[0;36m"
  printf "  +------------------------------------------------------+\n"
  printf "  |   \033[1;37mThanks for using YT-DL Termux. Goodbye!\033[0;36m           |\n"
  printf "  +------------------------------------------------------+\n"
  printf "\033[0m\n"
  exit 0
}

# ── Check dependencies on start ──────────────────────────────
check_deps() {
  local missing=()
  for tool in yt-dlp ffmpeg python3; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    err_msg "Missing tools: ${missing[*]}"
    printf "  \033[33mPlease run install.sh first:  bash install.sh\033[0m\n"
    echo ""
    exit 1
  fi
}

# ── Main menu ─────────────────────────────────────────────────
main_menu() {
  check_deps
  show_main_banner

  draw_box "Main Menu"
  echo ""
  menu_item "1" ">>" "Download YouTube channel"  "Enter URL and choose options"
  menu_item "2" "[]" "Open downloads folder"     "Browse downloaded files"
  menu_item "3" "**" "Update yt-dlp"             "Get the latest version"
  menu_item "4" "ii" "System info"               "Tool versions and storage"
  menu_item "5" "XX" "Exit"                      ""
  echo ""
  divider
  printf "  \033[36mChoose [1-5]:\033[0m "
  read -r main_choice

  case "$main_choice" in
    1)
      get_channel_url
      select_quality
      select_mode
      confirm_download
      run_download
      ;;
    2)
      printf "\n  \033[36mDownloads folder contents:\033[0m\n"
      ls -lh "$DOWNLOAD_ROOT" 2>/dev/null || echo "  (empty)"
      echo ""
      printf "  \033[2mPress ENTER to continue...\033[0m\n"
      read -r
      main_menu
      ;;
    3)
      printf "\n  \033[36mUpdating yt-dlp...\033[0m\n"
      pip install --upgrade yt-dlp 2>&1 | tail -3
      printf "  \033[32mUpdated!\033[0m\n"
      sleep 2
      main_menu
      ;;
    4)
      clear_screen
      draw_box "System Info"
      printf "  \033[1;37myt-dlp:\033[0m   %s\n" "$(yt-dlp --version 2>/dev/null)"
      printf "  \033[1;37mffmpeg:\033[0m   %s\n" "$(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3)"
      printf "  \033[1;37mpython:\033[0m   %s\n" "$(python3 --version 2>/dev/null)"
      printf "  \033[1;37mfolder:\033[0m   %s\n" "$DOWNLOAD_ROOT"
      local used
      used=$(du -sh "$DOWNLOAD_ROOT" 2>/dev/null | cut -f1)
      printf "  \033[1;37mused space:\033[0m %s\n" "${used:-0}"
      printf "\n"
      divider
      printf "  \033[2mPress ENTER to go back...\033[0m\n"
      read -r
      main_menu
      ;;
    5) goodbye ;;
    *) main_menu ;;
  esac
}

# ── Entry point ──────────────────────────────────────────────
main_menu
