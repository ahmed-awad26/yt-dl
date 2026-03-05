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

# ── Banner ───────────────────────────────────────────────────
show_banner() {
  clear
  echo -e "${CYAN}"
  echo "  ██╗   ██╗████████╗    ██████╗ ██╗      "
  echo "  ╚██╗ ██╔╝╚══██╔══╝    ██╔══██╗██║      "
  echo "   ╚████╔╝    ██║       ██║  ██║██║      "
  echo "    ╚██╔╝     ██║       ██║  ██║██║      "
  echo "     ██║      ██║       ██████╔╝███████╗ "
  echo "     ╚═╝      ╚═╝       ╚═════╝ ╚══════╝ "
  echo -e "${WHITE}   YouTube Channel Downloader for Termux${RESET}"
  echo -e "${YELLOW}   ─────────────────────────────────────${RESET}"
  echo -e "${MAGENTA}   v2.0  |  by YT-DL Team  |  Termux Edition${RESET}"
  echo ""
}

# ── Progress bar ─────────────────────────────────────────────
progress_bar() {
  local msg="$1"; local n="$2"; local total="$3"
  local pct=$(( n * 100 / total ))
  local filled=$(( pct / 5 ))
  local bar=""
  for ((i=0;i<filled;i++)); do bar+="█"; done
  for ((i=filled;i<20;i++)); do bar+="░"; done
  printf "\r  ${CYAN}[${GREEN}%s${CYAN}]${RESET} %3d%% — %s" "$bar" "$pct" "$msg"
}

# ── Step printer ─────────────────────────────────────────────
step()  { echo -e "\n${BOLD}${BLUE}[STEP]${RESET} $1"; }
ok()    { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
err()   { echo -e "  ${RED}✘${RESET}  $1"; }
info()  { echo -e "  ${CYAN}ℹ${RESET}  $1"; }

# ── Main installer ───────────────────────────────────────────
show_banner
echo -e "${WHITE}${BOLD}  📦 Starting Installation...${RESET}\n"

# ── 1. Storage permission ────────────────────────────────────
step "Requesting storage permission..."
echo ""
echo -e "  ${YELLOW}⚠  يحتاج البرنامج للوصول إلى التخزين الداخلي.${RESET}"
echo -e "  ${WHITE}سيظهر مربع حوار لطلب الإذن — اضغط ${GREEN}ALLOW${WHITE} للمتابعة.${RESET}"
echo ""
echo -e "  ${CYAN}اضغط ENTER لطلب إذن التخزين...${RESET}"
read -r

termux-setup-storage

echo ""
info "في انتظار منح إذن التخزين..."
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
  err "لم يُمنح إذن التخزين أو التخزين غير متاح."
  echo ""
  echo -e "  ${YELLOW}الحلول المقترحة:${RESET}"
  echo "  1. اذهب إلى إعدادات الهاتف → التطبيقات → Termux → الأذونات → التخزين → اسمح"
  echo "  2. أعد تشغيل Termux وشغّل install.sh مرة أخرى"
  echo "  3. في أندرويد 11+ قد تحتاج إلى منح إذن 'All files access'"
  echo ""
  echo -e "  ${CYAN}هل تريد المتابعة بمجلد Termux الداخلي فقط؟ (y/n)${RESET}"
  read -r fallback_ans
  if [[ "$fallback_ans" =~ ^[Yy]$ ]]; then
    SDCARD="$HOME/downloads"
    mkdir -p "$SDCARD"
    warn "سيتم التحميل في: $SDCARD"
  else
    err "تم إلغاء التثبيت. أعِد تشغيل البرنامج بعد منح الإذن."
    exit 1
  fi
fi

ok "إذن التخزين ممنوح ✔ — المجلد: $SDCARD"

# ── 2. Update pkg ────────────────────────────────────────────
step "تحديث قوائم الحزم..."
DEBIAN_FRONTEND=noninteractive pkg update -y 2>/dev/null | tail -1
ok "تم تحديث قوائم الحزم"

# ── 3. Install packages ──────────────────────────────────────
PACKAGES=(
  "python"          "Python 3 runtime"
  "ffmpeg"          "مشفر الفيديو والصوت"
  "curl"            "تنزيل الملفات"
  "wget"            "تنزيل الملفات (احتياطي)"
  "git"             "إدارة النسخ"
  "libxml2"         "مكتبة XML"
  "libxslt"         "مكتبة XSLT"
  "openssl"         "مكتبة التشفير"
  "termux-tools"    "أدوات Termux الأساسية"
  "jq"              "معالج JSON"
)

TOTAL_PKG=${#PACKAGES[@]}
i=0
step "تثبيت الحزم المطلوبة..."
echo ""

while [ $i -lt $TOTAL_PKG ]; do
  pkg_name="${PACKAGES[$i]}"
  pkg_desc="${PACKAGES[$((i+1))]}"
  progress_bar "تثبيت $pkg_name — $pkg_desc" $(( i/2 + 1 )) $(( TOTAL_PKG/2 ))
  DEBIAN_FRONTEND=noninteractive pkg install -y "$pkg_name" 2>/dev/null || {
    echo ""
    warn "تعذّر تثبيت $pkg_name — المتابعة..."
  }
  i=$((i + 2))
done
echo ""
ok "تم تثبيت جميع الحزم"

# ── 4. pip packages ──────────────────────────────────────────
step "تثبيت مكتبات Python..."
PIP_PKGS=("yt-dlp" "requests" "tqdm" "rich" "colorama")
TOTAL_PY=${#PIP_PKGS[@]}

for idx in "${!PIP_PKGS[@]}"; do
  p="${PIP_PKGS[$idx]}"
  progress_bar "pip install $p" $(( idx+1 )) $TOTAL_PY
  pip install --quiet --upgrade "$p" 2>/dev/null || {
    echo ""
    warn "تعذّر تثبيت $p عبر pip — المحاولة عبر pip3..."
    pip3 install --quiet --upgrade "$p" 2>/dev/null || warn "تخطي $p"
  }
done
echo ""
ok "تم تثبيت مكتبات Python"

# ── 5. Verify critical tools ─────────────────────────────────
step "التحقق من الأدوات الأساسية..."
ALL_OK=true
for tool in python python3 ffmpeg yt-dlp curl git; do
  if command -v "$tool" &>/dev/null; then
    ver=$(eval "$tool --version 2>/dev/null | head -1" || echo "OK")
    ok "$tool — $ver"
  else
    err "$tool غير موجود!"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = false ]; then
  warn "بعض الأدوات مفقودة. تحقق من اتصالك بالإنترنت وأعِد التثبيت."
fi

# ── 6. Make main script executable ──────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/ytdl.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/ytdl.py" 2>/dev/null || true

# ── 7. Create shortcut ───────────────────────────────────────
step "إنشاء اختصار سريع..."
SHORTCUT="$PREFIX/bin/ytdl"
cat > "$SHORTCUT" << SHORTCUT_EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "$SCRIPT_DIR"
bash ytdl.sh "\$@"
SHORTCUT_EOF
chmod +x "$SHORTCUT"
ok "يمكنك الآن كتابة 'ytdl' في أي مكان لتشغيل البرنامج"

# ── 8. Save storage path ─────────────────────────────────────
echo "SDCARD=$SDCARD" > "$SCRIPT_DIR/.config"
echo "DOWNLOAD_ROOT=$SDCARD/Download/YT-Channels" >> "$SCRIPT_DIR/.config"
ok "تم حفظ مسار التخزين: $SDCARD/Download/YT-Channels"

# ── 9. Prepare Git repo (ready to upload via browser) ────────
step "تجهيز المشروع للرفع على GitHub..."
cd "$SCRIPT_DIR"

# Init git if not already
if [ ! -d ".git" ]; then
  git init -q
  ok "تم تهيئة git repository"
else
  ok "git repository موجود مسبقاً"
fi

# Configure a default identity if none exists (required for commit)
if ! git config user.email &>/dev/null; then
  git config user.email "ytdl-termux@local"
  git config user.name  "YT-DL Termux"
fi

# Stage all files
git add -A

# Commit only if there's something new
if git diff --cached --quiet; then
  ok "لا يوجد تغييرات جديدة — الـ commit موجود مسبقاً"
else
  git commit -q -m "🚀 Initial release: YT Channel Downloader for Termux v2.0"
  ok "تم عمل git commit بنجاح"
fi

echo ""
echo -e "  ${WHITE}${BOLD}📂 المشروع جاهز للرفع على GitHub يدوياً:${RESET}"
echo ""
echo -e "  ${CYAN}الخطوات من المتصفح:${RESET}"
echo -e "  ${DIM}1. اذهب إلى https://github.com/new وأنشئ مستودعاً جديداً${RESET}"
echo -e "  ${DIM}2. اضغط 'uploading an existing file'${RESET}"
echo -e "  ${DIM}3. ارفع جميع الملفات من المجلد:${RESET}"
echo -e "  ${YELLOW}   $SCRIPT_DIR${RESET}"
echo -e "  ${DIM}4. اضغط 'Commit changes' — خلاص!${RESET}"
echo ""

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ┌─────────────────────────────────────────┐"
echo "  │   ✅  تم التثبيت بنجاح!                 │"
echo "  │                                         │"
echo "  │   لتشغيل البرنامج:                      │"
echo "  │     bash ytdl.sh                        │"
echo "  │   أو من أي مكان:                        │"
echo "  │     ytdl                                │"
echo "  └─────────────────────────────────────────┘"
echo -e "${RESET}"
echo -e "  ${CYAN}اضغط ENTER لبدء التشغيل الآن...${RESET}"
read -r
bash "$SCRIPT_DIR/ytdl.sh"
