# Security Policy & Best Practices

## Core Values
**Extreme Security (Security):** Data is held by the user, no vendor servers.

## Implementation Rules

### 1. Zero Logging
*   **NEVER** print plaintext logs of passwords, keys, or sensitive user data.

### 2. Memory Safety
*   **Clean Memory:** Clear memory as soon as possible after sensitive operations (although Dart has GC, do your best).

### 3. Least Privilege
*   **Permissions:** Request network and file permissions (especially on macOS/Android) only when necessary.

### 4. Zero Knowledge Architecture
*   **Encryption:** Data must be encrypted (AES-256) before writing to storage.
*   **Local First:** No data leaves the device unless synced to user's own cloud (iCloud/SAF).
