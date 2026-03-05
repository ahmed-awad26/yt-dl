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
  echo -e "${CYAN}${BOLD}"
  printf "  +"; printf -- '-%.0s' $(seq 1 $width); printf "+\n"
  printf "  |%${pad}s${WHITE}%s${CYAN}%${pad}s  |\n" "" "$title" ""
  printf "  +"; printf -- '-%.0s' $(seq 1 $width); printf "+\n"
  echo -e "${RESET}"
}

divider() {
  echo -e "  ${DIM}${CYAN}------------------------------------------------------${RESET}"
}

menu_item() {
  local num="$1"; local icon="$2"; local text="$3"; local desc="$4"
  echo -e "  ${CYAN}[${WHITE}${BOLD}$num${RESET}${CYAN}]${RESET} $icon ${WHITE}${BOLD}$text${RESET}  ${DIM}$desc${RESET}"
}

# ── Main banner ──────────────────────────────────────────────
show_main_banner() {
  clear_screen
  echo -e "${CYAN}"
  echo "  +------------------------------------------------------+"
  echo "  |                                                      |"
  echo "  |   ##  ##  ########    ######  ##                    |"
  echo "  |    ####   ##          ##  ##  ##                    |"
  echo "  |     ##    ######      ##  ##  ##                    |"
  echo "  |    ####   ##          ##  ##  ##                    |"
  echo "  |   ##  ##  ########    ######  ########              |"
  echo "  |                                                      |"
  echo -e "  |   ${WHITE}${BOLD}YouTube Channel Downloader -- Termux v2.0${CYAN}         |"
  echo "  |                                                      |"
  echo "  +------------------------------------------------------+"
  echo -e "${RESET}"
  echo -e "  ${DIM}Download dir: ${CYAN}$DOWNLOAD_ROOT${RESET}"
  echo -e "  ${DIM}Time: $(date '+%Y-%m-%d %H:%M')${RESET}"
  echo ""
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
  echo -e "  ${CYAN}Choose [1-8]:${RESET} "
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

ok_msg()   { echo -e "  ${GREEN}$1${RESET}"; sleep 1; }
err_msg()  { echo -e "  ${RED}[ERR] $1${RESET}"; }
warn_msg() { echo -e "  ${YELLOW}[!!] $1${RESET}"; sleep 1; }

# ── Mode selector ─────────────────────────────────────────────
select_mode() {
  clear_screen
  draw_box "Select Download Mode"
  echo ""
  menu_item "1" "[PL]" "Playlists only"           "Download channel playlists only"
  menu_item "2" "[UP]" "Uploads only"             "Download all channel videos"
  menu_item "3" "[ALL]" "Playlists + Uploads"     "Everything -- playlists and videos"
  menu_item "4" "[+U]" "All + Uncategorized"      "Everything + videos not in any playlist"
  menu_item "5" "[NEW]" "Latest update only"      "Only videos uploaded since last run"
  echo ""
  divider
  echo -e "  ${CYAN}Choose [1-5]:${RESET} "
  read -r mode_choice

  case "$mode_choice" in
    1) DL_MODE="playlists";         MODE_NAME="Playlists only" ;;
    2) DL_MODE="uploads";           MODE_NAME="Uploads only" ;;
    3) DL_MODE="all";               MODE_NAME="Playlists + Uploads" ;;
    4) DL_MODE="all_uncategorized"; MODE_NAME="All + Uncategorized" ;;
    5) DL_MODE="latest";            MODE_NAME="Latest update" ;;
    *) DL_MODE="all";               MODE_NAME="All (default)" ;;
  esac

  ok_msg "[OK] Mode selected: $MODE_NAME"
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
  echo -e "  ${WHITE}Paste any YouTube channel link -- all formats accepted:${RESET}"
  echo -e "  ${DIM}  https://youtube.com/@Name?si=xxxxx     (share link)${RESET}"
  echo -e "  ${DIM}  https://www.youtube.com/@Name          (handle)${RESET}"
  echo -e "  ${DIM}  https://www.youtube.com/channel/UCxxx  (channel ID)${RESET}"
  echo -e "  ${DIM}  https://www.youtube.com/c/Name         (custom URL)${RESET}"
  echo -e "  ${DIM}  https://www.youtube.com/user/Name      (legacy user)${RESET}"
  echo -e "  ${DIM}  https://m.youtube.com/@Name            (mobile)${RESET}"
  echo ""
  divider
  echo -e "  ${CYAN}Enter channel URL:${RESET} "
  read -r RAW_URL

  if [[ -z "$RAW_URL" ]]; then
    err_msg "URL is empty! Please try again."
    sleep 1
    get_channel_url
    return
  fi

  # Normalize the URL immediately (no network calls here)
  CHANNEL_URL=$(normalize_channel_url "$RAW_URL")
  echo -e "  ${DIM}Normalized: ${CYAN}$CHANNEL_URL${RESET}"

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
  echo -e "  ${WHITE}Channel:${RESET}      ${CYAN}$CHANNEL_NAME${RESET}"
  echo -e "  ${WHITE}URL:${RESET}          ${DIM}$CHANNEL_URL${RESET}"
  echo -e "  ${WHITE}Quality:${RESET}      ${GREEN}$QUALITY_NAME${RESET}"
  echo -e "  ${WHITE}Mode:${RESET}         ${YELLOW}$MODE_NAME${RESET}"
  echo -e "  ${WHITE}Save to:${RESET}      ${MAGENTA}$CHANNEL_DIR${RESET}"
  echo ""
  divider
  echo -e "  ${CYAN}[Y]${RESET} Start download   ${RED}[N]${RESET} Cancel"
  echo ""
  echo -e "  Choose: "
  read -r confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "  ${YELLOW}Cancelled.${RESET}"
    main_menu
    return
  fi

}

# ── Live progress display ────────────────────────────────────
show_download_ui() {
  clear_screen
  echo -e "${CYAN}"
  echo "  +------------------------------------------------------+"
  echo -e "  |   ${WHITE}${BOLD}Downloading...${CYAN}                                    |"
  echo "  +------------------------------------------------------+"
  echo -e "${RESET}"
  echo -e "  ${WHITE}Channel:${RESET} ${CYAN}$CHANNEL_NAME${RESET}"
  echo -e "  ${WHITE}Mode:${RESET}    ${YELLOW}$MODE_NAME${RESET}"
  echo -e "  ${WHITE}Quality:${RESET} ${GREEN}$QUALITY_NAME${RESET}"
  echo ""
  divider
  echo ""
}

# ── Draw progress bar ────────────────────────────────────────
# Usage: draw_progress <percent 0-100> <speed> <size>
draw_progress() {
  local pct="${1:-0}"
  local speed="${2:---}"
  local size="${3:---}"
  local bar_width=36
  local filled=$(( pct * bar_width / 100 ))
  local empty=$(( bar_width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty;  i++ )); do bar+="░"; done
  # pure printf with \r - NO newline so it rewrites same line
  printf "\r  \033[36m[\033[32m%s\033[36m]\033[0m \033[1m%3d%%\033[0m  \033[2m%-14s  %-10s\033[0m   " \
    "$bar" "$pct" "$speed" "$size"
}

# ── Parse yt-dlp output and show live progress ───────────────
# Reads yt-dlp stdout line by line and draws UI
stream_with_progress() {
  local log_file="$1"
  local current_title=""
  local last_title=""
  local vid_done=0
  local vid_skip=0

  while IFS= read -r line; do
    # Log everything
    echo "$line" >> "$log_file"

    # ── New video title ──────────────────────────────────────
    # [download] Destination: .../Title [id].mp4
    if echo "$line" | grep -qE '^\[download\] Destination:'; then
      # Strip path, strip [id].ext or .fNNN.ext suffixes
      current_title=$(echo "$line" | sed 's/.*Destination: //' | sed 's|.*/||' \
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
    elif echo "$line" | grep -qE '^\[download\] 100%'; then
      draw_progress 100 "" ""

    # ── ffmpeg merging ───────────────────────────────────────
    elif echo "$line" | grep -qE '^\[ffmpeg\]|^\[Merger\]'; then
      printf "\r  \033[1;33m⚙ Merging...\033[0m                                          "

    # ── Errors ───────────────────────────────────────────────
    elif echo "$line" | grep -qE '^ERROR'; then
      printf "\n  \033[0;31m[ERR] %s\033[0m\n" "$line"

    # ── Warnings (suppress noisy but harmless ones) ──────────
    elif echo "$line" | grep -qE '^WARNING'; then
      # Skip JS runtime warning and ffmpeg merge warning (cosmetic noise)
      if echo "$line" | grep -qE 'No supported JavaScript runtime|merging of multiple formats'; then
        : # suppress
      else
        printf "  \033[1;33m[!!] %s\033[0m\n" "$line"
      fi
    fi

  done
  printf "\n  \033[2mTotal downloaded: \033[32m%d\033[2m  |  Skipped: \033[33m%d\033[0m\n" "$vid_done" "$vid_skip"
}

# ── Run yt-dlp safely (args as real array, never split by shell) ─────────────
# Usage: run_ytdlp <log_file> <url> [extra_flag extra_flag ...]
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

  local args=(
    "--ignore-errors"
    "--no-abort-on-error"
    "--continue"
    "--retries" "5"
    "--fragment-retries" "10"
    "--retry-sleep" "3"
    "--concurrent-fragments" "4"
    "--merge-output-format" "mp4"
    "--embed-thumbnail"
    "--add-metadata"
    "--write-description"
    "--write-info-json"
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

  yt-dlp "${args[@]}" 2>&1 | stream_with_progress "$log_file"
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
        printf "\n  \033[36m◆ Uncategorized\033[0m\n\n"
        CURRENT_OUT_DIR="$CHANNEL_DIR/Uncategorized"
        mkdir -p "$CURRENT_OUT_DIR"
        run_ytdlp "$LOG" "$CHANNEL_URL" "--no-playlist"
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
      if [ -n "$DATE_AFTER" ]; then
        run_ytdlp "$LOG" "$CHANNEL_URL/videos" "--dateafter" "$DATE_AFTER"
      else
        run_ytdlp "$LOG" "$CHANNEL_URL/videos"
      fi
      date +%Y%m%d > "$DATEFILE"
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

  local PLAYLISTS
  # Use print for each field separately to avoid tab corruption
  PLAYLISTS=$(yt-dlp --flat-playlist \
    --print "%(playlist_id)s	%(playlist_title)s" \
    --no-warnings \
    "$CHANNEL_URL/playlists" 2>/dev/null | awk -F"\t" '!seen[$1]++')

  if [[ -z "$PLAYLISTS" ]]; then
    warn_msg "No playlists found for this channel."
    return
  fi

  local count=0
  while IFS=$'\t' read -r pl_id pl_title; do
    [[ -z "$pl_id" || "$pl_id" == "NA" ]] && continue
    count=$((count+1))

    # ── Keep full UTF-8 title (Arabic + all unicode) ──────────────
    # Only strip filesystem-unsafe chars: / \ : * ? " < > |  and leading dots
    local safe_title
    safe_title=$(printf '%s' "$pl_title" | sed 's|[/\\\\:*?"<>|]|_|g' | sed 's/^\.//')
    # Fallback if name became empty
    safe_title="${safe_title:-Playlist_$count}"

    CURRENT_OUT_DIR="$CHANNEL_DIR/Playlists/$safe_title"
    mkdir -p "$CURRENT_OUT_DIR"

    printf "\n  \033[35m[Playlist %d]\033[0m \033[1;37m%s\033[0m\n" "$count" "$pl_title"
    printf "  \033[2m→ %s\033[0m\n\n" "$CURRENT_OUT_DIR"

    run_ytdlp "$LOG" "https://www.youtube.com/playlist?list=$pl_id"
  done <<< "$PLAYLISTS"
}

# ── Completion screen ─────────────────────────────────────────
show_completion() {
  local log="$1"
  local errors=0
  [ -f "$log" ] && errors=$(grep -c "ERROR" "$log" 2>/dev/null || echo 0)
  local total=0
  [ -f "$log" ] && total=$(grep -c "\[download\]" "$log" 2>/dev/null || echo 0)

  clear_screen
  echo -e "${GREEN}${BOLD}"
  echo "  +------------------------------------------------------+"
  echo "  |                                                      |"
  echo "  |   Download complete!                                 |"
  echo "  |                                                      |"
  echo "  +------------------------------------------------------+"
  echo -e "${RESET}"
  echo -e "  ${WHITE}Channel:${RESET}          ${CYAN}$CHANNEL_NAME${RESET}"
  echo -e "  ${WHITE}Saved to:${RESET}         ${MAGENTA}$CHANNEL_DIR${RESET}"
  echo -e "  ${WHITE}Download ops:${RESET}     ${GREEN}$total${RESET}"
  [ "$errors" -gt 0 ] && \
    echo -e "  ${WHITE}Errors:${RESET}           ${RED}$errors${RESET} (check the log file)"
  echo -e "  ${WHITE}Log file:${RESET}         ${DIM}$log${RESET}"
  echo ""
  divider
  echo ""
  echo -e "  ${CYAN}[1]${RESET} Download another channel   ${CYAN}[2]${RESET} Exit"
  echo ""
  echo -e "  Choose: "
  read -r next_action

  case "$next_action" in
    1) main_menu ;;
    *) goodbye ;;
  esac
}

# ── Goodbye ──────────────────────────────────────────────────
goodbye() {
  clear_screen
  echo -e "${CYAN}"
  echo "  +------------------------------------------------------+"
  echo -e "  |   ${WHITE}Thanks for using YT-DL Termux. Goodbye!${CYAN}           |"
  echo "  +------------------------------------------------------+"
  echo -e "${RESET}"
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
    echo -e "  ${YELLOW}Please run install.sh first:  bash install.sh${RESET}"
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
  echo -e "  ${CYAN}Choose [1-5]:${RESET} "
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
      echo -e "\n  ${CYAN}Downloads folder contents:${RESET}"
      ls -lh "$DOWNLOAD_ROOT" 2>/dev/null || echo "  (empty)"
      echo ""
      echo -e "  ${DIM}Press ENTER to continue...${RESET}"
      read -r
      main_menu
      ;;
    3)
      echo -e "\n  ${CYAN}Updating yt-dlp...${RESET}"
      pip install --upgrade yt-dlp 2>&1 | tail -3
      echo -e "  ${GREEN}Updated!${RESET}"
      sleep 2
      main_menu
      ;;
    4)
      clear_screen
      draw_box "System Info"
      echo ""
      echo -e "  ${WHITE}yt-dlp:${RESET}   $(yt-dlp --version 2>/dev/null)"
      echo -e "  ${WHITE}ffmpeg:${RESET}   $(ffmpeg -version 2>/dev/null | head -1 | cut -d' ' -f3)"
      echo -e "  ${WHITE}python:${RESET}   $(python3 --version 2>/dev/null)"
      echo -e "  ${WHITE}folder:${RESET}   $DOWNLOAD_ROOT"
      local used
      used=$(du -sh "$DOWNLOAD_ROOT" 2>/dev/null | cut -f1)
      echo -e "  ${WHITE}used space:${RESET} ${used:-0}"
      echo ""
      divider
      echo -e "  ${DIM}Press ENTER to go back...${RESET}"
      read -r
      main_menu
      ;;
    5) goodbye ;;
    *) main_menu ;;
  esac
}

# ── Entry point ──────────────────────────────────────────────
main_menu
