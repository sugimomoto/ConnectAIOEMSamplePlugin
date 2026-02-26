FROM python:3.11-slim

# ビルドコンテキストはリポジトリルート（docker-compose.yml で context: .. を指定）
WORKDIR /app

# Python依存パッケージのインストール
COPY backend/requirements.txt backend/
RUN pip install --no-cache-dir -r backend/requirements.txt

# アプリケーションコードのコピー
COPY backend/ backend/
COPY frontend/ frontend/
COPY migrations/ migrations/

# 実行時に必要なディレクトリを作成
RUN mkdir -p backend/keys instance

# エントリポイントスクリプトのコピー（buildコンテキストからの相対パス）
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 5001

ENTRYPOINT ["/docker-entrypoint.sh"]
