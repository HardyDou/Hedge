Name:           hedge-cli
Version:        1.9.1
Release:        1%{?dist}
Summary:        Secure, local-first password manager CLI
License:        MIT
URL:            https://github.com/yourusername/hedge
BuildArch:      x86_64

%description
Hedge CLI lets you access your Hedge vault from the terminal.
Requires the Hedge desktop app to be running for IPC access,
or can read vault files directly with a master password.

%install
install -D -m 755 %{_sourcedir}/hedge %{buildroot}/usr/local/bin/hedge

%files
/usr/local/bin/hedge

%changelog
* Thu Mar 12 2026 Hedge Team <hello@hedge.app> - 1.9.1-1
- Release 1.9.1
