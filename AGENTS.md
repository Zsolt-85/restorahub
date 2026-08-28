# RestoraHub — AI Agent Guide

## Project Context

RestoraHub is a Flutter booking app transforming into a multi-tenant white-label SaaS platform. The pilot tenant is **RESTORE by MAYA**.

**Current state (2026-08-28)**: Sprints 1-6 complete. 228/228 tests passing, 0 analysis errors.

## Core Principles

1. **Tests are the contract** — Every change must preserve `flutter test` (228/228) and `flutter analyze` (0 errors).
2. **Additive only** — Never break existing data or APIs. Use backward-compatible `fromMap()` and default values.
3. **Minimal changes** — Solve the problem with the smallest effective change. Avoid refactoring "just because."
4. **No new dependencies** — Do not add packages without explicit justification.
5. **Security first** — Every feature must respect tenant isolation and role boundaries.

## Coding Standards

### Models
- Immutable fields + named constructor
- `fromMap(Map<String, dynamic>)` factory with safe defaults
- `toMap()` for Firestore serialization
- `copyWith()` for partial updates
- Enums for typed fields, parsed with safe fallback

### Repositories
- Abstract interface in `repositories/<name>_repository.dart`
- Firestore implementation in `repositories/firestore_<name>_repository.dart`
- Singleton pattern: `._()` + `static final instance`
- Wrap errors in `AppException` with user-safe messages
- All reads must filter by `businessId`

### Providers
- Extend `ChangeNotifier`
- Loading state: `_beginLoading()` / `_endLoading([String? error])`
- Repository via constructor or singleton fallback
- Notify listeners on state change

### Helpers
- Pure business logic, no Flutter widget dependencies where possible
- Static methods for stateless operations
- Testable in isolation

### Tests
- Mirror `lib/` structure in `test/`
- Use fake repositories (hand-written, no mockito)
- Group tests with `group('ClassName')`
- Cover constructor, `fromMap`, `toMap`, `copyWith`, edge cases

## Key Files

| File | Purpose |
|------|---------|
| `lib/models/business.dart` | Tenant model with subscription, branding, entitlements |
| `lib/models/plan.dart` | Plan definitions and FeatureGate registry |
| `lib/helpers/feature_gate.dart` | Runtime feature availability checks |
| `lib/helpers/route_guard_helper.dart` | Centralized auth/role redirects |
| `lib/helpers/business_lifecycle_helper.dart` | State machine transitions |
| `lib/providers/super_admin_provider.dart` | Tenant CRUD, user role management |
| `lib/providers/setup_wizard_provider.dart` | 9-step onboarding flow |
| `lib/repositories/firestore_*_repository.dart` | All Firestore data access |

## What NOT to Do

- Do not rename `professional` → `staff` or `specialty` → `category` without a migration plan
- Do not remove legacy `fromMap()` parsing until all Firestore docs are verified
- Do not add paid services or external APIs without discussion
- Do not expose secrets, API keys, or Firebase config in logs
- Do not bypass authentication for convenience
- Do not commit to `.kilo/` directory (gitignored)

## How to Resume

1. Pull latest from `origin/main`
2. Run `flutter test` (expect 228/228)
3. Run `flutter analyze` (expect 0 errors)
4. Pick up next sprint from `ROADMAP.md`

## Pilot Constraints

- Pilot tenant: RESTORE by MAYA
- Do not break existing RESTORE by MAYA data
- Feature flags must be additive
- Billing/Cloud Functions deferred to Sprint 9+
