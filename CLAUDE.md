# CLAUDE.md

このファイルは、リポジトリ内のコードを操作する Claude Code (claude.ai/code) へのガイダンスを提供します。

## 概要

CData Connect AI OEM のデモ環境（[ConnectAIOEMSample](https://github.com/sugimomoto/ConnectAIOEMSample)）を Docker で構築する **Claude Code プラグイン**です。スキルをインストールすることで、「デモ環境を作成して」と話しかけるだけで環境構築が実行されます。

## リポジトリ構造

```
ConnectAIOEMSamplePlugin/
├── skills/
│   └── create-oem-demo/         # スキル本体（自己完結）
│       ├── create-oem-demo.md   # Claude Code スキルプロンプト
│       ├── setup.sh             # セットアップスクリプト (Mac/Linux)
│       ├── setup.ps1            # セットアップスクリプト (Windows)
│       ├── Dockerfile           # Flask アプリ用 Docker イメージ
│       ├── docker-compose.yml   # コンテナ構成（context: .. はリポジトリルートを指す）
│       └── docker-entrypoint.sh # コンテナ起動・マイグレーション実行
├── plugin.json                  # プラグインマニフェスト
├── README.md                    # インストール手順
└── CLAUDE.md                    # このファイル
```

## スキルのインストール先

| ファイル | インストール先 |
|---|---|
| `skills/create-oem-demo/create-oem-demo.md` | `~/.claude/commands/create-oem-demo.md` |
| `skills/create-oem-demo/`（全ファイル） | `~/.claude/skills/create-oem-demo/` |

スキルプロンプトが `~/.claude/skills/create-oem-demo/setup.sh`（または `docker/setup.sh`）を自動検出して実行します。

## セットアップスクリプトの動作

`setup.sh` / `setup.ps1` は `SCRIPT_DIR`（スクリプト自身の場所）を基点に動作します：

1. `REPO_DIR` を自動解決（親ディレクトリに `backend/app.py` があればそこ、なければ ConnectAIOEMSample をクローン）
2. `${REPO_DIR}/docker/` に Docker 設定ファイルが無ければ `SCRIPT_DIR` からコピー（スタンドアロン実行対応）
3. RSA 2048bit 鍵ペアを生成し `${REPO_DIR}/backend/keys/` に保存
4. `${REPO_DIR}/backend/.env` を生成
5. `docker compose -f ${REPO_DIR}/docker/docker-compose.yml up --build -d` でコンテナを起動

## Docker 構成

コンテナ化された Flask アプリ（エントリ: `backend.app:create_app`）がポート **5001** で動作します。

- **ビルドコンテキスト:** `context: ..`（`docker/` の親 = リポジトリルート）
- **Dockerfile の参照:** `backend/`、`frontend/`、`migrations/` をコピー
- **ボリューム:** `backend/.env`・`backend/keys/`（読み取り専用）、`app_data`（SQLite 永続化）

## 設定変数（`backend/.env`）

| 変数 | 説明 |
|---|---|
| `SECRET_KEY` | Flask セッションシークレット（32 バイト hex） |
| `DATABASE_URL` | `sqlite:///datahub.db` |
| `CONNECT_AI_BASE_URL` | `https://cloud.cdata.com/api` |
| `CONNECT_AI_PARENT_ACCOUNT_ID` | CData Connect AI アカウント ID |
| `CONNECT_AI_PRIVATE_KEY_PATH` | コンテナ内の RSA 秘密鍵ファイルパス |
| `APP_BASE_URL` | OAuth コールバックのベース URL（デフォルト: `http://localhost:5001`） |
| `ENCRYPTION_KEY` | DB 内の Claude API キーを暗号化する Fernet キー |
