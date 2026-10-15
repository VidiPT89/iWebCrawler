#!/bin/bash
# Packages the browser extension for Chrome, Brave, Edge, Opera and Firefox (one Manifest V3 build).
# Safari gets the same folder through the iWebCrawler Safari extension targets in Xcode.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cp "$root/iWebCrawler/Resources/Spider.js" "$root/extension/spider.js"
version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$root/extension/manifest.json")"
mkdir -p "$root/build/extension"
archive="$root/build/extension/iWebCrawler-extension-$version.zip"
rm -f "$archive"
(cd "$root/extension" && zip -qr -X "$archive" . -x '.DS_Store' '*/.DS_Store')
echo "$archive"
