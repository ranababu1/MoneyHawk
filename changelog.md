# Changelog

## 2026-10-27

- Added Flutter app shell at the repo root (Android + iOS targets), Riverpod
  state management, paper/live mode banner (paper default).
- Added `.gitignore` entries for secrets, keystores and local DB files.
- Added `changelog.md` and `currentstate.md`.
- Tests: `dart format`, `flutter analyze` (no issues), `flutter test`
  (2 passed). Android/iOS builds not yet run.
- Decision (user): everything lives inside the Flutter app; no separate
  backend. This deviates from plan.md sections 1, 4 and 5; plan.md has not
  been edited and the deviation still needs a formal plan update.
- plan.md and instructions.md updated (user-approved) for the app-only
  architecture: no backend; on-device risk engine, order manager and Groww
  adapter; secure storage; foreground-only autonomous execution.
- `flutter build apk --debug` succeeded.
