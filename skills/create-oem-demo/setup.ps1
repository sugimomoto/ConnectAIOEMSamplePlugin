# =============================================================================
# ConnectAIOEMSample - Docker セットアップスクリプト (Windows PowerShell)
# 使い方:
#   リポジトリ内から実行 : powershell -ExecutionPolicy Bypass -File docker\setup.ps1
#   スタンドアロン実行   : powershell -ExecutionPolicy Bypass -File setup.ps1
# =============================================================================
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
# パス解決
# ─────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ParentDir = Split-Path -Parent $ScriptDir

# ─────────────────────────────────────────────
# 表示ユーティリティ
# ─────────────────────────────────────────────
function Write-Info    { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK]   $args" -ForegroundColor Green }
function Write-Warn    { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err     { Write-Host "[ERROR] $args" -ForegroundColor Red; exit 1 }

# ─────────────────────────────────────────────
# バナー
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║   ConnectAIOEMSample  Docker セットアップ        ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor White
Write-Host ""

# ─────────────────────────────────────────────
# 前提条件チェック
# ─────────────────────────────────────────────
Write-Info "前提条件を確認しています..."

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Err "Docker が見つかりません。Docker Desktop をインストールしてください。"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git が見つかりません。Git for Windows をインストールしてください。"
}

try { docker info 2>&1 | Out-Null }
catch { Write-Err "Docker が起動していません。Docker Desktop を起動してからやり直してください。" }

Write-Success "Docker / git を確認しました"

# ─────────────────────────────────────────────
# リポジトリの準備
# ─────────────────────────────────────────────
if (Test-Path (Join-Path $ParentDir "backend\app.py")) {
    # docker\ フォルダがリポジトリ内にある通常のケース
    $RepoDir = $ParentDir
    Write-Info "リポジトリを検出しました: $RepoDir"
} elseif (Test-Path "backend\app.py") {
    # カレントディレクトリがリポジトリルートのケース
    $RepoDir = (Get-Location).Path
    Write-Info "リポジトリを検出しました: $RepoDir"
} else {
    Write-Info "GitHub からリポジトリをクローンします..."
    git clone https://github.com/sugimomoto/ConnectAIOEMSample
    Set-Location ConnectAIOEMSample
    $RepoDir = (Get-Location).Path
    Write-Success "クローン完了: $RepoDir"
}

# ─────────────────────────────────────────────
# Docker設定ファイルの配置（スタンドアロン実行時）
# ─────────────────────────────────────────────
$DockerDir = Join-Path $RepoDir "docker"
if (-not (Test-Path (Join-Path $DockerDir "docker-compose.yml"))) {
    Write-Info "Docker設定ファイルをリポジトリにコピーしています..."
    if (-not (Test-Path $DockerDir)) { New-Item -ItemType Directory -Path $DockerDir | Out-Null }
    Copy-Item (Join-Path $ScriptDir "Dockerfile")            -Destination $DockerDir
    Copy-Item (Join-Path $ScriptDir "docker-compose.yml")    -Destination $DockerDir
    Copy-Item (Join-Path $ScriptDir "docker-entrypoint.sh")  -Destination $DockerDir
    Write-Success "Docker設定ファイルをコピーしました"
}

# ─────────────────────────────────────────────
# ユーザー入力 - CData Connect AI 設定
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "━━━ CData Connect AI 設定 ━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host ""

$AccountId = ""
while ([string]::IsNullOrWhiteSpace($AccountId)) {
    $AccountId = Read-Host "  CData Connect AI Parent Account ID"
    if ([string]::IsNullOrWhiteSpace($AccountId)) {
        Write-Warn "Account ID は必須です。もう一度入力してください。"
    }
}

$AppBaseUrl = Read-Host "  APP_BASE_URL [http://localhost:5001]"
if ([string]::IsNullOrWhiteSpace($AppBaseUrl)) { $AppBaseUrl = "http://localhost:5001" }

Write-Success "設定を受け付けました"

# ─────────────────────────────────────────────
# RSA 鍵ペアの生成（.NET 組み込み暗号ライブラリを使用）
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "━━━ RSA 鍵ペアの生成 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host ""

$KeysDir = Join-Path $RepoDir "backend\keys"
if (-not (Test-Path $KeysDir)) { New-Item -ItemType Directory -Path $KeysDir | Out-Null }

Write-Info "RSA 2048bit 鍵ペアを生成しています..."

$rsa = [System.Security.Cryptography.RSA]::Create(2048)

# --- 秘密鍵 (PKCS#1 PEM) ---
$privBytes  = $rsa.ExportRSAPrivateKey()
$privBase64 = [System.Convert]::ToBase64String($privBytes)
$privPem    = "-----BEGIN RSA PRIVATE KEY-----`n"
for ($i = 0; $i -lt $privBase64.Length; $i += 64) {
    $privPem += $privBase64.Substring($i, [Math]::Min(64, $privBase64.Length - $i)) + "`n"
}
$privPem += "-----END RSA PRIVATE KEY-----"
Set-Content -Path (Join-Path $KeysDir "private.key") -Value $privPem -Encoding UTF8

# --- 公開鍵 (SubjectPublicKeyInfo PEM) ---
$pubBytes  = $rsa.ExportSubjectPublicKeyInfo()
$pubBase64 = [System.Convert]::ToBase64String($pubBytes)
$pubPem    = "-----BEGIN PUBLIC KEY-----`n"
for ($i = 0; $i -lt $pubBase64.Length; $i += 64) {
    $pubPem += $pubBase64.Substring($i, [Math]::Min(64, $pubBase64.Length - $i)) + "`n"
}
$pubPem += "-----END PUBLIC KEY-----"
Set-Content -Path (Join-Path $KeysDir "public.key") -Value $pubPem -Encoding UTF8

Write-Success "RSA 鍵ペアを生成しました"
Write-Host ""

# ─────────────────────────────────────────────
# 公開鍵の表示
# ─────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  【重要】以下の公開鍵を CData Connect AI に登録してください  ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host $pubPem -ForegroundColor White
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  公開鍵はファイルにも保存されています:                       ║" -ForegroundColor Yellow
Write-Host "║  $KeysDir\public.key" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "  登録手順:"
Write-Host "  1. 上記の公開鍵をコピーしてください"
Write-Host "  2. CData Connect AI の管理コンソールにログイン"
Write-Host "  3. 対象の Parent Account に公開鍵を登録"
Write-Host ""
Read-Host "  公開鍵の CData への登録が完了したら Enter を押してください"

# ─────────────────────────────────────────────
# 各種シークレットの生成
# ─────────────────────────────────────────────
Write-Host ""
Write-Info "SECRET_KEY を生成しています..."
$secretBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
$SecretKey   = [System.BitConverter]::ToString($secretBytes).Replace("-", "").ToLower()

Write-Info "ENCRYPTION_KEY (Fernet) を生成しています..."
$encBytes      = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
$EncryptionKey = [System.Convert]::ToBase64String($encBytes).Replace("+", "-").Replace("/", "_")

Write-Success "シークレットキーを生成しました"

# ─────────────────────────────────────────────
# .env ファイルの生成
# ─────────────────────────────────────────────
Write-Host ""
Write-Info "backend\.env を生成しています..."

$envContent = @"
# Flask
FLASK_ENV=production
FLASK_DEBUG=0
SECRET_KEY=$SecretKey

# データベース
DATABASE_URL=sqlite:///datahub.db

# CData Connect AI
CONNECT_AI_BASE_URL=https://cloud.cdata.com/api
CONNECT_AI_PARENT_ACCOUNT_ID=$AccountId

# RSA 秘密鍵ファイルパス（コンテナ内パス）
CONNECT_AI_PRIVATE_KEY_PATH=backend/keys/private.key

# アプリケーションベース URL（OAuth コールバック用）
APP_BASE_URL=$AppBaseUrl

# Claude API Key 暗号化キー（Fernet 対称暗号）
ENCRYPTION_KEY=$EncryptionKey
"@

Set-Content -Path (Join-Path $RepoDir "backend\.env") -Value $envContent -Encoding UTF8
Write-Success "backend\.env を生成しました"

# ─────────────────────────────────────────────
# Docker コンテナのビルド & 起動
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "━━━ Docker コンテナを起動します ━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host ""

$ComposeFile = Join-Path $RepoDir "docker\docker-compose.yml"
Write-Info "イメージをビルドしてコンテナを起動しています..."
docker compose -f $ComposeFile up --build -d

Write-Info "アプリケーションの起動を待っています..."
Start-Sleep -Seconds 15

# ─────────────────────────────────────────────
# 完了メッセージ
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   セットアップ完了！                              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  アクセス URL : $AppBaseUrl" -ForegroundColor White
Write-Host ""
Write-Host "  便利なコマンド:"
Write-Host "    ログ確認  : docker compose -f $ComposeFile logs -f"
Write-Host "    停止      : docker compose -f $ComposeFile down"
Write-Host "    再起動    : docker compose -f $ComposeFile restart"
Write-Host "    完全削除  : docker compose -f $ComposeFile down -v"
Write-Host ""
Write-Host "  設定ファイル:"
Write-Host "    環境設定  : $RepoDir\backend\.env"
Write-Host "    公開鍵    : $KeysDir\public.key"
Write-Host "    秘密鍵    : $KeysDir\private.key"
Write-Host ""
