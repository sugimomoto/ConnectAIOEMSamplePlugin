#!/bin/bash
# =============================================================================
# ConnectAIOEMSample - Docker セットアップスクリプト (Mac/Linux)
# 使い方:
#   リポジトリ内から実行 : bash docker/setup.sh
#   スタンドアロン実行   : bash setup.sh  (リポジトリを自動クローン)
# =============================================================================
set -e

# ─────────────────────────────────────────────
# パス解決
# ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

# ─────────────────────────────────────────────
# 表示ユーティリティ
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ─────────────────────────────────────────────
# バナー
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   ConnectAIOEMSample  Docker セットアップ        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# ─────────────────────────────────────────────
# 前提条件チェック
# ─────────────────────────────────────────────
info "前提条件を確認しています..."

command -v docker   &>/dev/null || error "Docker が見つかりません。Docker Desktop をインストールしてください。"
command -v git      &>/dev/null || error "git が見つかりません。Git をインストールしてください。"
command -v openssl  &>/dev/null || error "openssl が見つかりません。OpenSSL をインストールしてください。"

docker info &>/dev/null || error "Docker が起動していません。Docker Desktop を起動してからやり直してください。"

success "Docker / git / openssl を確認しました"

# ─────────────────────────────────────────────
# リポジトリの準備
# ─────────────────────────────────────────────
if [ -f "${PARENT_DIR}/backend/app.py" ]; then
    # docker/ フォルダがリポジトリ内にある通常のケース
    REPO_DIR="${PARENT_DIR}"
    info "リポジトリを検出しました: ${REPO_DIR}"
elif [ -f "$(pwd)/backend/app.py" ]; then
    # カレントディレクトリがリポジトリルートのケース
    REPO_DIR="$(pwd)"
    info "リポジトリを検出しました: ${REPO_DIR}"
else
    # リポジトリが見つからない → クローン
    info "GitHub からリポジトリをクローンします..."
    git clone https://github.com/sugimomoto/ConnectAIOEMSample
    REPO_DIR="$(pwd)/ConnectAIOEMSample"
    success "クローン完了: ${REPO_DIR}"
fi

# ─────────────────────────────────────────────
# Docker設定ファイルの配置（スタンドアロン実行時）
# ─────────────────────────────────────────────
if [ ! -f "${REPO_DIR}/docker/docker-compose.yml" ]; then
    info "Docker設定ファイルをリポジトリにコピーしています..."
    mkdir -p "${REPO_DIR}/docker"
    cp "${SCRIPT_DIR}/Dockerfile"            "${REPO_DIR}/docker/"
    cp "${SCRIPT_DIR}/docker-compose.yml"    "${REPO_DIR}/docker/"
    cp "${SCRIPT_DIR}/docker-entrypoint.sh"  "${REPO_DIR}/docker/"
    chmod +x "${REPO_DIR}/docker/docker-entrypoint.sh"
    success "Docker設定ファイルをコピーしました"
fi

# ─────────────────────────────────────────────
# ユーザー入力 - CData Connect AI 設定
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━ CData Connect AI 設定 ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

while true; do
    read -rp "  CData Connect AI Parent Account ID: " ACCOUNT_ID
    [ -n "${ACCOUNT_ID}" ] && break
    warn "Account ID は必須です。もう一度入力してください。"
done

echo ""
read -rp "  APP_BASE_URL [http://localhost:5001]: " APP_BASE_URL
APP_BASE_URL="${APP_BASE_URL:-http://localhost:5001}"

success "設定を受け付けました"

# ─────────────────────────────────────────────
# RSA 鍵ペアの生成
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━ RSA 鍵ペアの生成 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

mkdir -p "${REPO_DIR}/backend/keys"

info "RSA 2048bit 秘密鍵を生成しています..."
openssl genrsa -out "${REPO_DIR}/backend/keys/private.key" 2048 2>/dev/null

info "公開鍵を抽出しています..."
openssl rsa -in "${REPO_DIR}/backend/keys/private.key" -pubout \
    -out "${REPO_DIR}/backend/keys/public.key" 2>/dev/null

success "RSA 鍵ペアを生成しました"
echo ""

# ─────────────────────────────────────────────
# 公開鍵の表示
# ─────────────────────────────────────────────
echo -e "${BOLD}${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║  【重要】以下の公開鍵を CData Connect AI に登録してください  ║${NC}"
echo -e "${BOLD}${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
cat "${REPO_DIR}/backend/keys/public.key"
echo ""
echo -e "${BOLD}${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║  公開鍵はファイルにも保存されています:                       ║${NC}"
echo -e "${BOLD}${YELLOW}║  ${REPO_DIR}/backend/keys/public.key"
echo -e "${BOLD}${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  登録手順:"
echo "  1. 上記の公開鍵をコピーしてください"
echo "  2. CData Connect AI の管理コンソールにログイン"
echo "  3. 対象の Parent Account に公開鍵を登録"
echo ""
read -rp "  公開鍵の CData への登録が完了したら Enter を押してください..."

# ─────────────────────────────────────────────
# 各種シークレットの生成
# ─────────────────────────────────────────────
echo ""
info "SECRET_KEY を生成しています..."
SECRET_KEY=$(openssl rand -hex 32)

info "ENCRYPTION_KEY (Fernet) を生成しています..."
if command -v python3 &>/dev/null; then
    ENCRYPTION_KEY=$(python3 -c "import os, base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())")
else
    ENCRYPTION_KEY=$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '\n')
fi

success "シークレットキーを生成しました"

# ─────────────────────────────────────────────
# .env ファイルの生成
# ─────────────────────────────────────────────
echo ""
info "backend/.env を生成しています..."

cat > "${REPO_DIR}/backend/.env" << EOF
# Flask
FLASK_ENV=production
FLASK_DEBUG=0
SECRET_KEY=${SECRET_KEY}

# データベース
DATABASE_URL=sqlite:///datahub.db

# CData Connect AI
CONNECT_AI_BASE_URL=https://cloud.cdata.com/api
CONNECT_AI_PARENT_ACCOUNT_ID=${ACCOUNT_ID}

# RSA 秘密鍵ファイルパス（コンテナ内パス）
CONNECT_AI_PRIVATE_KEY_PATH=backend/keys/private.key

# アプリケーションベース URL（OAuth コールバック用）
APP_BASE_URL=${APP_BASE_URL}

# Claude API Key 暗号化キー（Fernet 対称暗号）
ENCRYPTION_KEY=${ENCRYPTION_KEY}
EOF

success "backend/.env を生成しました"

# ─────────────────────────────────────────────
# Docker コンテナのビルド & 起動
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━ Docker コンテナを起動します ━━━━━━━━━━━━━━━━━━${NC}"
echo ""

info "イメージをビルドしてコンテナを起動しています..."
docker compose -f "${REPO_DIR}/docker/docker-compose.yml" up --build -d

info "アプリケーションの起動を待っています..."
WAIT_SECS=30
for i in $(seq 1 "${WAIT_SECS}"); do
    if docker compose -f "${REPO_DIR}/docker/docker-compose.yml" ps 2>/dev/null | grep -q "running\|Up"; then
        break
    fi
    sleep 1
done
sleep 5

# ─────────────────────────────────────────────
# 完了メッセージ
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║   セットアップ完了！                              ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  アクセス URL : ${BOLD}${APP_BASE_URL}${NC}"
echo ""
echo "  便利なコマンド（docker/ ディレクトリから実行）:"
echo "    ログ確認  : docker compose -f ${REPO_DIR}/docker/docker-compose.yml logs -f"
echo "    停止      : docker compose -f ${REPO_DIR}/docker/docker-compose.yml down"
echo "    再起動    : docker compose -f ${REPO_DIR}/docker/docker-compose.yml restart"
echo "    完全削除  : docker compose -f ${REPO_DIR}/docker/docker-compose.yml down -v"
echo ""
echo "  設定ファイル:"
echo "    環境設定  : ${REPO_DIR}/backend/.env"
echo "    公開鍵    : ${REPO_DIR}/backend/keys/public.key"
echo "    秘密鍵    : ${REPO_DIR}/backend/keys/private.key"
echo ""
