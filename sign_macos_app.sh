#!/bin/bash
# macOS 应用签名脚本

APP_PATH="$1"

if [ -z "$APP_PATH" ]; then
    echo "用法: ./sign_macos_app.sh Hedge.app"
    exit 1
fi

echo "重新签名应用..."
codesign --force --deep --sign - "$APP_PATH"

echo "验证签名..."
codesign -vvv "$APP_PATH"

echo "完成！"
