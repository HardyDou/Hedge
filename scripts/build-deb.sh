#!/bin/bash
# Build .deb package for Hedge CLI
# Usage: ./scripts/build-deb.sh <version>

set -e

VERSION="${1:-1.9.1}"
VERSION="${VERSION#v}"  # strip leading 'v' if present
ARCH="amd64"
PKG_NAME="hedge-cli"
PKG_DIR="dist/deb/${PKG_NAME}_${VERSION}_${ARCH}"

echo "Building .deb for ${PKG_NAME} v${VERSION}..."

# Create directory structure
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/local/bin"
mkdir -p "${PKG_DIR}/usr/share/doc/${PKG_NAME}"

# Copy binary (must be pre-built)
if [ ! -f "build/hedge" ]; then
  echo "Error: build/hedge not found. Run: cd cli && dart compile exe bin/hedge.dart -o ../build/hedge"
  exit 1
fi
cp build/hedge "${PKG_DIR}/usr/local/bin/hedge"
chmod 755 "${PKG_DIR}/usr/local/bin/hedge"

# DEBIAN/control
cat > "${PKG_DIR}/DEBIAN/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: Hedge Team <hello@hedge.app>
Description: Secure, local-first password manager CLI
 Hedge CLI lets you access your Hedge vault from the terminal.
 Requires the Hedge desktop app to be running for IPC access,
 or can read vault files directly with a master password.
Homepage: https://github.com/HardyDou/hedge
EOF

# DEBIAN/copyright
cat > "${PKG_DIR}/usr/share/doc/${PKG_NAME}/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: hedge-cli
Source: https://github.com/HardyDou/hedge

Files: *
Copyright: $(date +%Y) Hedge Team
License: MIT
EOF

# Build the .deb
dpkg-deb --build --root-owner-group "${PKG_DIR}"
echo "Built: dist/deb/${PKG_NAME}_${VERSION}_${ARCH}.deb"
