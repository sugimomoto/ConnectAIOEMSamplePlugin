---
description: CData Connect AI OEM デモ環境を Docker で構築する。「デモ環境を作成して」「OEM環境をセットアップして」「CData Connect AI OEM のデモ環境を作成して」などのリクエストで使用。
allowed-tools: Bash, Read, Write, Edit
---

CData Connect AI OEM のデモ環境（ConnectAIOEMSample）を Docker で対話的にセットアップしてください。

## あなたのタスク

以下のステップを順番に実行してください。

### 1. セットアップスクリプトの場所を確認

以下の順番で `setup.sh`（Mac/Linux）または `setup.ps1`（Windows）を探し、パスを記録してください：

1. `~/.claude/skills/create-oem-demo/setup.sh`（グローバルインストール時）
2. `docker/setup.sh`（リポジトリ内に配置時）

どちらも見つからない場合は、以下を案内してください：
```
スキルが正しくインストールされていません。
README.md の「インストール手順」を参照してください。
```

### 2. 前提条件チェック

以下を Bash で確認し、不足があればインストール方法を案内してください。
- `docker info` — Docker Desktop が起動しているか
- `git --version` — git がインストールされているか
- Mac/Linux の場合は `openssl version` も確認

### 3. セットアップスクリプトの実行

ステップ1で見つけたパスのスクリプトを実行してください。

**Mac/Linux の場合:**
```bash
bash <step1で見つけたsetup.shのパス>
```

**Windows の場合:**
```powershell
powershell -ExecutionPolicy Bypass -File <step1で見つけたsetup.ps1のパス>
```

スクリプトの実行中、以下の対話ステップでユーザーをサポートしてください：

- **CData Connect AI Parent Account ID の入力を求められたとき** — ユーザーにアカウント ID の入力を促してください
- **公開鍵が表示されたとき** — CData Connect AI 管理コンソールへの登録手順を補足説明してください
- **エラーが発生したとき** — エラー内容を解析して原因と対処法を日本語で説明してください

### 4. 完了確認

スクリプト出力に表示された docker compose コマンドを使って確認してください。
- コンテナが `Up` になっているか
- 直近のログにエラーが出ていないか

問題があれば原因を調査して修正を提案してください。

### 5. 完了メッセージ

セットアップが成功したら以下を伝えてください：
- アクセス URL（デフォルト: http://localhost:5001）
- よく使うコマンド（ログ確認・停止・再起動）
- 次のステップ（アカウント登録・Claude API キー設定など）
