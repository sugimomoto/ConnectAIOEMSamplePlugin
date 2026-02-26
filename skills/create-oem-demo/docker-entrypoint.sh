#!/bin/bash
set -e

echo "=== DB マイグレーションを実行します ==="
python -m flask --app backend.app:create_app db upgrade

echo "=== アプリケーションを起動します (port 5001) ==="
exec python -m flask --app backend.app:create_app run --host=0.0.0.0 --port=5001
