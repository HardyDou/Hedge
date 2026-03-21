---
name: hedge-cli
description: Interact with Hedge password manager CLI - get passwords, list items, search, lock/unlock, and sync vaults.
user-invokable: true
args:
  - name: action
    description: The CLI action to perform (get, list, search, lock, unlock, sync, config)
    required: true
  - name: query
    description: Query/item name for get or search commands
    required: false
  - name: field
    description: Field to retrieve (username, password, url, notes)
    required: false
---

Interact with Hedge password manager CLI to manage passwords and vault operations.

## MANDATORY PREPARATION

**IMPORTANT: Agent must do everything automatically. Never ask the user to install anything.**

### Step 1: Install This Skill (Auto)

Check if skill exists. If not, install it automatically:

```bash
# Check if skill is already available
ls ~/.claude/skills/hedge-cli

# If not, try skills.sh (may require user's GitHub repo to be public)
npx skills add <owner>/hedge@hedge-cli 2>/dev/null || true

# Or create symlink from current project
ln -sf "$(pwd)/skills/hedge-cli" ~/.claude/skills/hedge-cli 2>/dev/null || true
```

### Step 2: Install & Build Hedge CLI (Auto)

The user needs Hedge CLI. You MUST build it automatically:

**Prerequisites check:**
```bash
which dart || which flutter
```

**Build CLI (do this automatically):**
```bash
# Navigate to cli directory
cd cli

# Install dependencies
dart pub get

# Compile executable
dart compile exe bin/hedge.dart -o ../build/hedge

# Make executable
chmod +x ../build/hedge

# Verify
../build/hedge --version
```

**Add to PATH (optional, for convenience):**
```bash
export PATH="$PATH:$(pwd)/build"
# Or copy globally
sudo cp ../build/hedge /usr/local/bin/hedge 2>/dev/null || cp ../build/hedge ~/bin/hedge 2>/dev/null || true
```

---

## Available Commands

### get - Retrieve Password

```bash
hedge get <item>
hedge get <item> --field <username|url|notes>
hedge get <item> --no-copy
```

### list - List All Items

```bash
hedge list
```

### search - Search Items

```bash
hedge search <query>
```

### lock - Lock Session

```bash
hedge lock
```

### unlock - Unlock Session

```bash
hedge unlock
hedge unlock --output-token
```

### sync - Sync Vault

```bash
hedge sync
hedge sync --status
hedge sync --force-upload
hedge sync --force-download
```

### config - Manage Configuration

```bash
hedge config show
hedge config webdav --url <url> --user <user> --password <password> --path <path>
```

---

## Authentication Modes

1. **Biometric Mode** (default): Connects to Desktop App via IPC, uses Touch ID/Face ID
   - Session lasts 15 minutes
   - Requires Desktop App running

2. **Standalone Mode**: Use `--no-app` flag with master password
   - Set `HEDGE_MASTER_PASSWORD` env var for non-interactive use

---

## Environment Variables

- `HEDGE_VAULT_PATH`: Vault file location
- `HEDGE_MASTER_PASSWORD`: Master password for --no-app mode
- `HEDGE_WEBDAV_URL`: WebDAV server URL
- `HEDGE_WEBDAV_USERNAME`: WebDAV username
- `HEDGE_WEBDAV_PASSWORD`: WebDAV password

---

## Execution (Fully Automatic)

When user asks for password/access:

1. **Auto-install skill** if needed (symlink or npx)
2. **Auto-build CLI** if not built (`cd cli && dart pub get && dart compile`)
3. **Run command** - Execute hedge command
4. **Handle auth** - Guide through Touch ID / password if needed
5. **Return result** - Show password or item to user

All done automatically. Never ask user to install anything.

---

## Security Notes

- AES-256-GCM encryption
- Session tokens time-limited (5-15 minutes)
- Clipboard auto-cleared after retrieval
