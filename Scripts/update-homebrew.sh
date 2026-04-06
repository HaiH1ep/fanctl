#!/bin/bash
# Updates the Homebrew formula after a new release.
# Usage: ./Scripts/update-homebrew.sh v0.1.0

set -euo pipefail

VERSION="${1:?Usage: $0 <version-tag>}"
VERSION_NUM="${VERSION#v}"

TARBALL_URL="https://github.com/HaiH1ep/fanctl/releases/download/${VERSION}/fanctl-${VERSION}-arm64-macos.tar.gz"

echo "Downloading tarball to compute sha256..."
SHA256=$(curl -sL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')

echo "Version: ${VERSION_NUM}"
echo "SHA256:  ${SHA256}"

FORMULA_PATH="../homebrew-fanctl/Formula/fanctl.rb"

if [ ! -f "$FORMULA_PATH" ]; then
    echo "Error: Formula not found at $FORMULA_PATH"
    echo "Make sure homebrew-fanctl repo is cloned next to fanctl repo."
    exit 1
fi

# Update version and sha256 in formula
sed -i '' "s/version \".*\"/version \"${VERSION_NUM}\"/" "$FORMULA_PATH"
sed -i '' "s/sha256 \".*\"/sha256 \"${SHA256}\"/" "$FORMULA_PATH"

echo "Updated $FORMULA_PATH"
echo "Don't forget to commit and push homebrew-fanctl!"
