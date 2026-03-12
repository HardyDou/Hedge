# Hedge CLI Installation

## macOS (Homebrew)

```bash
# Add the tap
brew tap yourusername/hedge

# Install
brew install hedge

# Verify
hedge --version
```

## Linux (Debian/Ubuntu - APT)

### Option 1: Download .deb directly

```bash
# Download the latest .deb from releases
wget https://github.com/yourusername/hedge/releases/latest/download/hedge-cli_1.9.0_amd64.deb

# Install
sudo dpkg -i hedge-cli_1.9.0_amd64.deb

# Verify
hedge --version
```

### Option 2: Add APT repository (coming soon)

```bash
# Add GPG key
curl -fsSL https://apt.hedge.app/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/hedge-archive-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/hedge-archive-keyring.gpg] https://apt.hedge.app stable main" | sudo tee /etc/apt/sources.list.d/hedge.list

# Install
sudo apt update
sudo apt install hedge-cli
```

## Linux (Fedora/RHEL/CentOS - YUM/DNF)

### Option 1: Download .rpm directly

```bash
# Download the latest .rpm from releases
wget https://github.com/yourusername/hedge/releases/latest/download/hedge-cli-1.9.0-1.x86_64.rpm

# Install (Fedora/RHEL 8+)
sudo dnf install ./hedge-cli-1.9.0-1.x86_64.rpm

# Or (RHEL 7/CentOS 7)
sudo yum install ./hedge-cli-1.9.0-1.x86_64.rpm

# Verify
hedge --version
```

### Option 2: Add YUM repository (coming soon)

```bash
# Add repository
sudo tee /etc/yum.repos.d/hedge.repo << EOF
[hedge]
name=Hedge CLI Repository
baseurl=https://yum.hedge.app/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://yum.hedge.app/gpg.key
EOF

# Install
sudo dnf install hedge-cli  # or: sudo yum install hedge-cli

# Verify
hedge --version
```

## Linux (Generic)

```bash
# Download tarball
wget https://github.com/yourusername/hedge/releases/latest/download/hedge-cli-linux-x64.tar.gz

# Extract
tar -xzf hedge-cli-linux-x64.tar.gz

# Move to PATH
sudo mv hedge /usr/local/bin/

# Verify
hedge --version
```

## Windows

```powershell
# Download from releases
Invoke-WebRequest -Uri "https://github.com/yourusername/hedge/releases/latest/download/hedge-cli-windows-x64.zip" -OutFile "hedge-cli.zip"

# Extract
Expand-Archive -Path hedge-cli.zip -DestinationPath C:\Program Files\Hedge

# Add to PATH (run as Administrator)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Hedge", "Machine")

# Verify (restart terminal)
hedge --version
```

## Build from source

```bash
# Clone repository
git clone https://github.com/yourusername/hedge.git
cd hedge/cli

# Install dependencies
dart pub get

# Compile
dart compile exe bin/hedge.dart -o hedge

# Move to PATH
sudo mv hedge /usr/local/bin/
```

## Usage

```bash
# Get a password (requires Hedge app running)
hedge get github.com

# List all entries
hedge list

# Search entries
hedge search amazon

# Lock the session
hedge lock
```

For more details, see the [CLI documentation](../cli/README.md).
