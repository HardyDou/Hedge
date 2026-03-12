#!/bin/bash
# Build .rpm package for Hedge CLI
# Usage: ./scripts/build-rpm.sh <version>

set -e

VERSION="${1:-1.9.0}"
ARCH="x86_64"
PKG_NAME="hedge-cli"
BUILD_ROOT="dist/rpm/BUILD"
RPMS_DIR="dist/rpm/RPMS/${ARCH}"

echo "Building .rpm for ${PKG_NAME} v${VERSION}..."

# Create RPM build directory structure
mkdir -p "dist/rpm"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "${BUILD_ROOT}/usr/local/bin"
mkdir -p "${BUILD_ROOT}/usr/share/doc/${PKG_NAME}"

# Copy binary (must be pre-built)
if [ ! -f "build/hedge" ]; then
  echo "Error: build/hedge not found. Run: cd cli && dart compile exe bin/hedge.dart -o ../build/hedge"
  exit 1
fi
cp build/hedge "${BUILD_ROOT}/usr/local/bin/hedge"
chmod 755 "${BUILD_ROOT}/usr/local/bin/hedge"

# Create spec file
cat > "dist/rpm/SPECS/${PKG_NAME}.spec" << EOF
Name:           ${PKG_NAME}
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Secure, local-first password manager CLI
License:        MIT
URL:            https://github.com/yourusername/hedge
BuildArch:      ${ARCH}

%description
Hedge CLI lets you access your Hedge vault from the terminal.
Requires the Hedge desktop app to be running for IPC access,
or can read vault files directly with a master password.

%install
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/usr/share/doc/%{name}
cp %{_builddir}/usr/local/bin/hedge %{buildroot}/usr/local/bin/hedge
chmod 755 %{buildroot}/usr/local/bin/hedge

%files
/usr/local/bin/hedge

%changelog
* $(date "+%a %b %d %Y") Hedge Team <hello@hedge.app> - ${VERSION}-1
- Release ${VERSION}
EOF

# Build the RPM
rpmbuild --define "_topdir $(pwd)/dist/rpm" \
         --define "_builddir ${BUILD_ROOT}" \
         --buildroot "${BUILD_ROOT}" \
         -bb "dist/rpm/SPECS/${PKG_NAME}.spec"

# Move the built RPM to a predictable location
mkdir -p dist/rpm/output
cp "${RPMS_DIR}/${PKG_NAME}-${VERSION}-"*.rpm dist/rpm/output/
echo "Built: dist/rpm/output/${PKG_NAME}-${VERSION}-1.${ARCH}.rpm"
