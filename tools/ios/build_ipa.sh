#!/usr/bin/env bash
# 在 macOS 上一键打出「清账」的未签名 IPA，供 Sideloadly / AltStore 侧载。
# 也可以直接接真机运行：flutter run -d <你的设备>
set -euo pipefail

cd "$(dirname "$0")/../.."
echo "==> 当前目录: $(pwd)"

if ! command -v flutter >/dev/null 2>&1; then
  echo "未找到 flutter，请先安装 Flutter SDK 并加入 PATH" >&2
  exit 1
fi

flutter pub get

if [ -d ios ]; then
  (cd ios && pod install --repo-update)
fi

flutter build ios --release --no-codesign

rm -rf build/ipa qingzhang-unsigned.ipa
mkdir -p build/ipa/Payload
cp -R build/ios/iphoneos/Runner.app build/ipa/Payload/

(cd build/ipa && zip -qry ../qingzhang-unsigned.ipa Payload)

ls -lh qingzhang-unsigned.ipa
echo "==> 完成：qingzhang-unsigned.ipa"
echo "    把这个文件拷到 Windows，用 Sideloadly 签上自己的 Apple ID 安装。"
