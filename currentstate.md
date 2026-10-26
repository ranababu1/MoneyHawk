# Current State

**Branch:** main (remote: origin, https://github.com/ranababu1/MoneyHawk.git)
**Phase:** 1 (Foundation), just started. Phase 0 (Groww API / regulatory
verification) is NOT done.

## Implemented
- Flutter app shell at repo root (`lib/main.dart`): Riverpod, paper-mode
  banner (default), live-mode banner variant. Nothing else.

## Not implemented
Groww adapter, market data, orders, risk engine, AI, auth, persistence,
backend, CI.

## Architecture decision (user, 2026-10-27)
All logic is to live inside the Flutter app (single codebase, no backend).
Consequences to design for: no background execution guarantee on phones
(autonomous trading cannot be assumed to run while the app is suspended),
Groww credentials must be kept in Android Keystore / iOS Keychain only
(flutter_secure_storage), and risk checks must still gate every order in
code that AI/strategy code cannot bypass. plan.md and instructions.md were updated to match (2026-10-27).

## Build/test
- `dart format .` ok, `flutter analyze` no issues, `flutter test` 2 passed.
- `flutter build apk --debug` ok. iOS build not run (needs macOS).

## Next step
Phase 0: verify current official Groww Trade API docs (auth, orders,
market data, rate limits) and regulatory constraints, then
design the Dart module skeleton.
