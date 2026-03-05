#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   YT-Channel-Downloader — Termux Installer
#   GitHub: https://github.com/YOUR_USERNAME/ytdl-termux
# ============================================================

set -e

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; RESET='\033[0m'; BOLD='\033[1m'
DIM='\033[2m'

# ── Banner ───────────────────────────────────────────────────
show_banner() {
  clear
  printf "\033[0;36m\n"
  echo "  ██╗   ██╗████████╗    ██████╗ ██╗      "
  echo "  ╚██╗ ██╔╝╚══██╔══╝    ██╔══██╗██║      "
  echo "   ╚████╔╝    ██║       ██║  ██║██║      "
  echo "    ╚██╔╝     ██║       ██║  ██║██║      "
  echo "     ██║      ██║       ██████╔╝███████╗ "
  echo "     ╚═╝      ╚═╝       ╚═════╝ ╚══════╝ "
  printf "\033[1;37m   YouTube Channel Downloader for Termux\033[0m\n"
  printf "\033[1;33m   ─────────────────────────────────────\033[0m\n"
  printf "\033[0;35m   v2.0  |  by YT-DL Team  |  Termux Edition\033[0m\n"
  echo ""
}

# ── Progress bar ─────────────────────────────────────────────
progress_bar() {
  local msg="$1"; local n="$2"; local total="$3"
  local pct=$(( n * 100 / total ))
  local filled=$(( pct / 5 ))
  local bar=""
  for ((i=0;i<filled;i++)); do bar+="#"; done
  for ((i=filled;i<20;i++)); do bar+="."; done
  printf "\r  \033[0;36m[\033[0;32m%s\033[0;36m]\033[0m %3d%% -- %s" "$bar" "$pct" "$msg"
}

# ── Step printer ─────────────────────────────────────────────
step()  { printf "\n\033[1m\033[0;34m[STEP]\033[0m $1\n"; }
ok()    { printf "  \033[0;32m[OK]\033[0m  $1\n"; }
warn()  { printf "  \033[1;33m[!!]\033[0m  $1\n"; }
err()   { printf "  \033[0;31m[ERR]\033[0m $1\n"; }
info()  { printf "  \033[0;36m[..]\033[0m  $1\n"; }

# ── Main installer ───────────────────────────────────────────
show_banner
printf "\033[1;37m\033[1m  Starting Installation...\033[0m\n"

# ── 1. Storage permission ────────────────────────────────────
step "Requesting storage permission..."
echo ""
printf "  \033[1;33m[!!] Storage access is required to save downloads.\033[0m\n"
printf "  \033[1;37mA dialog will appear -- tap \033[0;32mALLOW\033[1;37m to continue.\033[0m\n"
echo ""
printf "  \033[0;36mPress ENTER to request storage permission...\033[0m\n"
read -r

termux-setup-storage

echo ""
info "Waiting for storage permission..."
sleep 3

# Verify access
STORAGE_OK=false
for dir in "$HOME/storage/shared" "/sdcard" "/storage/emulated/0"; do
  if [ -d "$dir" ] && [ -w "$dir" ]; then
    STORAGE_OK=true
    SDCARD="$dir"
    break
  fi
done

if [ "$STORAGE_OK" = false ]; then
  err "Storage permission was not granted or storage is unavailable."
  echo ""
  printf "  \033[1;33mSuggested fixes:\033[0m\n"
  echo "  1. Settings -> Apps -> Termux -> Permissions -> Storage -> Allow"
  echo "  2. Restart Termux and run install.sh again"
  echo "  3. Android 11+: grant 'All files access' in settings"
  echo ""
  printf "  \033[0;36mContinue using Termux internal storage only? (y/n)\033[0m\n"
  read -r fallback_ans
  if [[ "$fallback_ans" =~ ^[Yy]$ ]]; then
    SDCARD="$HOME/downloads"
    mkdir -p "$SDCARD"
    warn "Downloads will be saved to: $SDCARD"
  else
    err "Installation cancelled. Re-run after granting permission."
    exit 1
  fi
fi

ok "Storage permission granted -- path: $SDCARD"

# ── 2. Upgrade all packages (REQUIRED before ffmpeg install) ────────────────
step "Upgrading Termux packages (required for ffmpeg compatibility)..."
echo ""
warn "This may take a few minutes -- please wait..."
echo ""
DEBIAN_FRONTEND=noninteractive pkg upgrade -y 2>&1 | grep -E "upgraded|newly installed|error" | tail -5
ok "Packages upgraded"

# ── 3. Install packages ──────────────────────────────────────
PACKAGES=(
  "python"          "Python 3 runtime"
  "ffmpeg"          "Video/audio merger"
  "curl"            "File downloader"
  "wget"            "File downloader (backup)"
  "git"             "Version control"
  "libxml2"         "XML library"
  "libxslt"         "XSLT library"
  "openssl"         "Encryption library"
  "termux-tools"    "Core Termux tools"
  "jq"              "JSON processor"
)

TOTAL_PKG=${#PACKAGES[@]}
i=0
step "Installing required packages..."
echo ""

while [ $i -lt $TOTAL_PKG ]; do
  pkg_name="${PACKAGES[$i]}"
  pkg_desc="${PACKAGES[$((i+1))]}"
  progress_bar "Installing $pkg_name -- $pkg_desc" $(( i/2 + 1 )) $(( TOTAL_PKG/2 ))
  DEBIAN_FRONTEND=noninteractive pkg install -y "$pkg_name" 2>/dev/null || {
    echo ""
    warn "Could not install $pkg_name -- skipping..."
  }
  i=$((i + 2))
done
echo ""
ok "All packages installed"

# ── 3b. Fix ffmpeg if broken ──────────────────────────────────
step "Verifying ffmpeg..."
if ! ffmpeg -version &>/dev/null; then
  warn "ffmpeg has a linking issue -- attempting fix..."
  echo ""
  DEBIAN_FRONTEND=noninteractive pkg install -y --fix-broken ffmpeg 2>/dev/null || true
  # Try once more after fix-broken
  if ! ffmpeg -version &>/dev/null; then
    warn "ffmpeg still not working. Try manually: pkg install ffmpeg --fix-broken"
  else
    ok "ffmpeg fixed successfully"
  fi
else
  ok "ffmpeg is working"
fi

# ── 4. pip packages ──────────────────────────────────────────
step "Installing Python libraries..."
PIP_PKGS=("yt-dlp" "requests" "tqdm" "rich" "colorama")
TOTAL_PY=${#PIP_PKGS[@]}

for idx in "${!PIP_PKGS[@]}"; do
  p="${PIP_PKGS[$idx]}"
  progress_bar "pip install $p" $(( idx+1 )) $TOTAL_PY
  pip install --quiet --upgrade "$p" 2>/dev/null || {
    echo ""
    warn "pip failed for $p -- trying pip3..."
    pip3 install --quiet --upgrade "$p" 2>/dev/null || warn "Skipping $p"
  }
done
echo ""
ok "Python libraries installed"

# ── 5. Verify critical tools ─────────────────────────────────
step "Verifying required tools..."
ALL_OK=true
for tool in python python3 ffmpeg yt-dlp curl git; do
  if command -v "$tool" &>/dev/null; then
    ver=$("$tool" --version 2>/dev/null | head -1 || echo "OK")
    ok "$tool -- $ver"
  else
    err "$tool not found!"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = false ]; then
  warn "Some tools are missing. Check your internet connection and re-run."
fi

# ── 6. Make main script executable ──────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/ytdl.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/ytdl.py" 2>/dev/null || true

# ── 7. Create shortcut ───────────────────────────────────────
step "Creating global shortcut..."
SHORTCUT="$PREFIX/bin/ytdl"
cat > "$SHORTCUT" << SHORTCUT_EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$SCRIPT_DIR"
bash ytdl.sh "\$@"
SHORTCUT_EOF
chmod +x "$SHORTCUT"
ok "You can now type 'ytdl' from anywhere to launch the program"

# ── 8. Save storage path ─────────────────────────────────────
echo "SDCARD=$SDCARD" > "$SCRIPT_DIR/.config"
echo "DOWNLOAD_ROOT=$SDCARD/Download/YT-Channels" >> "$SCRIPT_DIR/.config"
ok "Storage path saved: $SDCARD/Download/YT-Channels"

# ── 9. Prepare Git repo (ready to upload via browser) ────────
step "Preparing project for GitHub upload..."
cd "$SCRIPT_DIR"

if [ ! -d ".git" ]; then
  git init -q
  ok "Git repository initialized"
else
  ok "Git repository already exists"
fi

if ! git config user.email &>/dev/null; then
  git config user.email "ytdl-termux@local"
  git config user.name  "YT-DL Termux"
fi

git add -A

if git diff --cached --quiet; then
  ok "No new changes -- commit already exists"
else
  git commit -q -m "Initial release: YT Channel Downloader for Termux v2.0"
  ok "Git commit created successfully"
fi

echo ""
printf "  \033[1;37m\033[1mProject is ready to upload to GitHub manually:\033[0m\n"
echo ""
printf "  \033[0;36mSteps (via browser):\033[0m\n"
printf "  \033[2m1. Go to https://github.com/new and create a new repository\033[0m\n"
printf "  \033[2m2. Click 'uploading an existing file'\033[0m\n"
printf "  \033[2m3. Upload all files from:\033[0m\n"
printf "  \033[1;33m   $SCRIPT_DIR\033[0m\n"
printf "  \033[2m4. Click 'Commit changes' -- done!\033[0m\n"
echo ""

# ── Done ─────────────────────────────────────────────────────
echo ""
printf "\033[0;32m\033[1m\n"
echo "  +------------------------------------------+"
echo "  |   Installation complete!                 |"
echo "  |                                          |"
echo "  |   To run the program:                    |"
echo "  |     bash ytdl.sh                         |"
echo "  |   Or from anywhere:                      |"
echo "  |     ytdl                                 |"
echo "  +------------------------------------------+"
printf "\033[0m\n"
printf "  \033[0;36mPress ENTER to launch now...\033[0m\n"
read -r
bash "$SCRIPT_DIR/ytdl.sh"
