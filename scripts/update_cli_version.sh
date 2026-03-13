#!/bin/bash
# 更新 CLI 版本号
# 用法: ./scripts/update_version.sh 1.9.2

NEW_VERSION=$1
if [ -z "$NEW_VERSION" ]; then
    echo "用法: ./update_version.sh <新版本号>"
    echo "例如: ./update_version.sh 1.9.2"
    exit 1
fi

# 更新 pubspec.yaml
sed -i '' "s/^version: .*/version: $NEW_VERSION/" cli/pubspec.yaml

# 更新 version.dart
sed -i '' "s/const version = '.*'/const version = '$NEW_VERSION'/" cli/lib/version.dart

echo "✓ 版本已更新为 $NEW_VERSION"
echo "  - cli/pubspec.yaml"
echo "  - cli/lib/version.dart"
