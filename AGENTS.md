# Repository Guidelines

## Project Structure & Module Organization
This repository is a Flutter app. Core code lives in `lib/`:
- `lib/main.dart`: app entry point and provider wiring.
- `lib/models/`: domain models (`coffee_record.dart`, `farm.dart`, `worker.dart`, `worker_record.dart`).
- `lib/providers/`: app state and Firestore orchestration.
- `lib/screens/`: feature screens (auth, farms, workers, sales, profile, home).
- `lib/services/`: integrations (auth, user profile, PDF export).
- `lib/widgets/`: reusable UI components.

Tests live in `test/` (currently `widget_test.dart`). Static assets are in `assets/`. Platform folders: `android/`, `web/`, `windows/`.

## Build, Test, and Development Commands
- `flutter pub get`: install dependencies.
- `flutter run`: run locally on connected device/emulator.
- `flutter analyze`: run static analysis with Flutter lints.
- `flutter test`: run automated tests.
- `flutter build apk` (or `flutter build web`): create production builds.

Run `flutter analyze && flutter test` before opening a PR.

## Coding Style & Naming Conventions
Use Dart/Flutter defaults with `flutter_lints` (`analysis_options.yaml`).
- Indentation: 2 spaces; keep lines readable.
- Naming: English only for files, classes, methods, variables, and new Firestore fields.
- File names: `snake_case.dart`; classes: `PascalCase`; members: `camelCase`.
- Prefer small widgets/providers and explicit types at API boundaries.

If touching legacy Spanish Firestore keys, keep backward-compatible reads unless a migration is part of the change.

## Testing Guidelines
Use `flutter_test` for widget and unit coverage.
- Test files: `*_test.dart`.
- Name tests by behavior (example: `Login screen renders basic fields`).
- Add/adjust tests for provider logic, form validation, and critical flows when behavior changes.

## Commit & Pull Request Guidelines
Git history uses Conventional Commit prefixes (`feat:`, `fix:`). Keep this format and write messages in English.
- Example: `fix: prevent duplicate worker names on save`.

PRs should include:
- Clear summary of user-visible and technical changes.
- Linked issue/task ID (if available).
- Screenshots or short video for UI changes.
- Notes about data model/Firestore key changes and migration impact.
