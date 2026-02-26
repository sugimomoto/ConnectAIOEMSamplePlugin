# CData Connect AI OEM Plugin for Claude Code

CData Connect AI OEM のデモ環境（[ConnectAIOEMSample](https://github.com/sugimomoto/ConnectAIOEMSample)）を Docker で構築する Claude Code プラグインです。

## インストール

Claude Code で以下のコマンドを実行してください：

```
以下のリポジトリのスキルを私の環境に追加して
https://github.com/sugimomoto/ConnectAIOEMSamplePlugin
```

## 使い方

インストール後、Claude Code で以下のように話しかけるだけで環境構築が始まります：

```
CData Connect AI OEM のデモ環境を作成して
```

Claude が対話形式でセットアップをガイドします。

## セットアップの流れ

「デモ環境を作成して」と依頼すると、Claude が以下を自動実行します：

1. Docker Desktop・git・openssl の確認
2. ConnectAIOEMSample リポジトリのクローン（未取得の場合）
3. RSA 2048bit 鍵ペアの生成
4. CData Connect AI 管理コンソールへの公開鍵登録ガイド
5. `.env` ファイルの生成（Secret Key・Encryption Key を自動生成）
6. Docker コンテナのビルドと起動

完了後、`http://localhost:5001` でアクセス可能になります。

## 前提条件

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) がインストール・起動済みであること
- `git` がインストール済みであること
- Mac/Linux の場合は `openssl` がインストール済みであること
- CData Connect AI の Parent Account ID（管理コンソールで確認）

## 手動インストール

`/plugin install` が使えない場合は手動でインストールできます。

### Mac / Linux

```bash
git clone https://github.com/sugimomoto/ConnectAIOEMSamplePlugin
cd ConnectAIOEMSamplePlugin
mkdir -p ~/.claude/commands ~/.claude/skills/create-oem-demo
cp skills/create-oem-demo/create-oem-demo.md ~/.claude/commands/
cp -r skills/create-oem-demo/ ~/.claude/skills/create-oem-demo/
```

### Windows (PowerShell)

```powershell
git clone https://github.com/sugimomoto/ConnectAIOEMSamplePlugin
cd ConnectAIOEMSamplePlugin
New-Item -ItemType Directory -Force -Path "$HOME\.claude\commands", "$HOME\.claude\skills\create-oem-demo"
Copy-Item skills\create-oem-demo\create-oem-demo.md -Destination "$HOME\.claude\commands\"
Copy-Item skills\create-oem-demo\* -Destination "$HOME\.claude\skills\create-oem-demo\" -Recurse
```

## スキル構成

```
skills/
└── create-oem-demo/
    ├── create-oem-demo.md   # Claude Code スキルプロンプト
    ├── setup.sh             # セットアップスクリプト (Mac/Linux)
    ├── setup.ps1            # セットアップスクリプト (Windows)
    ├── Dockerfile           # Flask アプリ用 Docker イメージ
    ├── docker-compose.yml   # コンテナ構成
    └── docker-entrypoint.sh # コンテナ起動スクリプト
```
