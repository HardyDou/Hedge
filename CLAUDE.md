## Design Context

### Users
Privacy-conscious, tech-savvy users who distrust third-party cloud services. They use Hedge on multiple devices (Mac + mobile) and want complete control over their data. Their primary job: securely store and quickly retrieve passwords and 2FA codes without friction. They're comfortable with self-managed sync (iCloud Drive, WebDAV, Nextcloud).

### Brand Personality
**安全、简洁、可信** — Secure, Simple, Trustworthy.

Hedge is like a reliable tool that doesn't draw attention to itself. It does its job quietly and precisely. No flashiness, no unnecessary decoration. The hedgehog mascot (刺猬) captures this: unassuming but well-protected.

### Emotional Goals
The interface should make users feel:
- **Safe** — data is protected, nothing leaks
- **Calm** — no anxiety, no clutter, no surprises
- **In control** — they own their data, they decide everything
- **Professional** — tool-grade precision and reliability

### Aesthetic Direction
**Reference:** Things 3 — elegant, focused, native-feeling iOS/macOS app with strong typographic hierarchy and purposeful use of whitespace. Clean without being sterile.

**Visual tone:** Minimal, refined, native Cupertino. No custom widgets that fight the platform. Typography-led hierarchy. Generous whitespace. Subtle use of color — system blue for actions, muted backgrounds, no decorative gradients.

**Anti-references:** Avoid 1Password's marketing-heavy visual style. Avoid anything that looks like a web app wrapped in a native shell. No Material Design influence.

**Theme:** Both light and dark modes are first-class citizens. Dark mode uses the existing `#1C1C1E` / `#2C2C2E` / `#38383A` surface hierarchy. Light mode uses `#FFFFFF` / `#F2F2F7` / `#E5E5EA`. Both should feel equally polished.

### Tech Stack
- Flutter 3.x with 100% Cupertino design (no Material)
- Riverpod 2.x for state management
- AES-256-GCM encryption, Argon2id key derivation
- WebDAV sync (Nextcloud, Synology, Nutstore, iCloud Drive)
- Platforms: iOS, macOS, Android

### Design Principles
1. **Native first** — Follow Cupertino conventions strictly. If iOS/macOS does it a certain way, do it that way. Don't reinvent platform patterns.
2. **Security is visible** — Passwords hidden by default, clipboard auto-clears, biometric gates. Security UX should feel reassuring, not paranoid.
3. **Calm hierarchy** — Information is layered. Primary actions are obvious. Secondary details recede. Nothing competes for attention unnecessarily.
4. **Whitespace is structure** — Use spacing to group and separate, not decorative elements. Let content breathe.
5. **Consistency over cleverness** — Predictable patterns build trust. Avoid surprising interactions. When in doubt, do what the platform does.
