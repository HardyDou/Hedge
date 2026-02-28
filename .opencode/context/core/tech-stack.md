# NotePassword Technology Stack

## Core Technologies
*   **Framework:** Flutter (Latest Stable)
*   **Language:** Dart (Strongly typed, Null safety)
*   **State Management:** Riverpod (No GetX, No Bloc)
*   **UI Style:** **Cupertino (iOS Style)**. Consistent iOS-style experience even on Android.
*   **Crypto:** **Pure Dart Implementation** (`cryptography` + `encrypt` packages).
    *   *Note: Rust FFI was used in early stages but has been migrated to pure Dart. DO NOT attempt to reintroduce Rust code unless explicitly requested.*
*   **Storage:** Encrypted JSON file + Platform-specific storage (iOS Documents / Android SAF).

## Architecture Pattern
**MVVM + Clean Architecture**

*   **Presentation Layer (`lib/presentation/`)**:
    *   **Pages:** Page logic. Separated into `mobile/` and `desktop/` directories.
    *   **Widgets:** Reusable components.
    *   **Providers:** Riverpod state management.

*   **Domain/Data Layer (`lib/core/`, `lib/data/`)**:
    *   **Single Source of Truth:** Dart Core handles all business logic.
    *   **Repository Pattern:** Abstract data storage.
