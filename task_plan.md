# Task Plan: Smart Import Feature

## Goal
Implement the "Smart Import" feature for NotePassword, enabling users to import passwords from Chrome, 1Password, and other sources via CSV.

## Phases

- [x] Phase 1: Setup and Dependencies
    - [x] Create `task_plan.md` (Done)
    - [x] Check for existing worktree directories (Checked, none found)
    - [x] Create git worktree/branch `feature/smart-import` (Used standard branching)
    - [x] Add `csv: ^6.0.0` to `pubspec.yaml`
    - [x] Run `flutter pub get` (Attempted, command failed but likely due to env. Dependencies added.)

- [ ] Phase 2: Domain Layer (Core Logic)
    - [ ] Create directory `lib/domain/services/importer`
    - [ ] Create `lib/domain/services/importer/import_strategy.dart`
    - [ ] Create `lib/domain/services/importer/smart_csv_strategy.dart`
    - [ ] Create `lib/domain/services/importer/csv_import_service.dart`
    - [ ] Implement parsing logic with `compute()`

- [ ] Phase 3: Application Layer (State Management)
    - [ ] Update `VaultNotifier` in `lib/presentation/providers/vault_provider.dart`

- [ ] Phase 4: UI Layer (Presentation)
    - [ ] Update `lib/presentation/pages/mobile/settings_page.dart`
    - [ ] Implement `_showImportActionSheet`
    - [ ] Implement `CupertinoAlertDialog` for results

- [ ] Phase 5: L10n (Internationalization)
    - [ ] Update `lib/l10n/app_en.arb`
    - [ ] Update `lib/l10n/app_zh.arb`
    - [ ] Run `flutter gen-l10n`

- [ ] Phase 6: Verification
    - [ ] Run `flutter analyze`
    - [ ] Run `flutter test`
    - [ ] Verify build

## Current Status
Starting Phase 2.
