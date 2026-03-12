#!/bin/bash
# Build .rpm package for Hedge CLI
# Usage: ./scripts/build-rpm.sh <version>

set -e

VERSION="${1:-1.9.1}"
VERSION="${VERSION#v}"  # strip leading 'v' if present
ARCH="x86_64"
PKG_NAME="hedge-cli"
TOPDIR="$(pwd)/dist/rpm"

echo "Building .rpm for ${PKG_NAME} v${VERSION}..."

# Create RPM build directory structure
mkdir -p "${TOPDIR}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Copy binary into SOURCES so %install can find it
if [ ! -f "build/hedge" ]; then
  echo "Error: build/hedge not found. Run: cd cli && dart compile exe bin/hedge.dart -o ../build/hedge"
  exit 1
fi
cp build/hedge "${TOPDIR}/SOURCES/hedge"
chmod 755 "${TOPDIR}/SOURCES/hedge"

# Create spec file
cat > "${TOPDIR}/SPECS/${PKG_NAME}.spec" << EOF
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
install -D -m 755 %{_sourcedir}/hedge %{buildroot}/usr/local/bin/hedge

%files
/usr/local/bin/hedge

%changelog
* $(date "+%a %b %d %Y") Hedge Team <hello@hedge.app> - ${VERSION}-1
- Release ${VERSION}
EOF

# Build the RPM
rpmbuild --define "_topdir ${TOPDIR}" \
         -bb "${TOPDIR}/SPECS/${PKG_NAME}.spec"

# Move the built RPM to a predictable location
mkdir -p dist/rpm/output
cp "${TOPDIR}/RPMS/${ARCH}/${PKG_NAME}-${VERSION}-"*.rpm dist/rpm/output/
echo "Built: dist/rpm/output/${PKG_NAME}-${VERSION}-1.${ARCH}.rpm"
