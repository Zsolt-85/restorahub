# Premium Frontend Redesign — Design Spec

**Date:** 2026-09-25
**Status:** Proposed (awaiting user review; no implementation until approved)
**North star:** Fresha-grade flow intelligence wrapped in a calm, warm, editorial voice (Aesop / Apple Store, not nightclub-luxury).
**Pilot tenant:** RESTORE by MAYA (wellness/spa). All choices must white-label to other verticals (barbershop, clinic) via seed color + fonts + imagery.

## 1. Problem

RestoraHub reads as stock Material 3 circa defaults: system Roboto, teal seed, AppBar+ListView+ListTile screens, AlertDialog forms, zero brand moments (login, success, empty states all generic), no photography, no motion language. Competitors (Fresha, Booksy, ClassPass) win on photo discovery, pro profiles with portfolios, stepped wizards, and loyalty. Diagnosis from audit: "from 2000" is accurate.

## 2. Goals

1. Customer booking flow feels premium, simple, and fast: home → discovery → wizard → confirmation.
2. One shared visual language across all 25 screens, inherited from the centralized theme (no per-page hand-rolled styles).
3. White-label by construction: every brand choice flows from `BusinessBranding` + tenant assets, with safe fallbacks.
4. Zero regressions: `flutter test` green, `flutter analyze` 0 issues, additive changes only, l10n keys untouched (new copy reuses existing keys or adds keys with English fallback per existing pattern).

## 3. Non-goals (explicitly out)

- Backend, Firestore schema, repositories, providers logic (theme/provider wiring only where the visuals require it).
- Staff/admin density redesign (sub-project 3; customer flow ships first).
- Paid services, external image DAMs, Rive/Lottieflare, M3 Expressive community packages (rejected: new-dependency risk + white-label unpredictability; stock Flutter achieves the target look — Fry kit precedent).
- Renaming `professional`→`staff` or any model migration.

## 4. Design pillars

1. **Editorial calm.** Warm paper surfaces, ink text, one accent (tenant seed). Whitespace does the luxury work; no decorative gradients, no card-soup.
2. **Two families max.** Display serif for headings/hero numbers (pilot: Fraunces), clean sans for body/UI (pilot: Inter). Wired into `ThemeHelper.buildThemeData`; tenants override via branding.
3. **Photography first, monogram fallback.** Services and professionals show photos (`cached_network_image`, shimmer placeholder already owned). Missing photo → initial-monogram tile in tenant seed, never a grey box or generic icon avatar.
4. **One decision per screen.** The 1292-line booking form becomes a stepped wizard (service → professional → time → confirm) with a progress indicator and a persistent summary footer.
5. **Quiet motion.** One motion language: ~200ms eased transitions, one orchestrated moment per flow (confirmation), reduced-motion respected. Stock Flutter curves only.

## 5. Component library (`lib/widgets/premium/`)

Each unit: one responsibility, constructed from theme roles + tenant assets, testable with widget tests.

| Unit | Does | Consumes | Produces |
|------|------|----------|----------|
| `ServiceCard` | Photo, name, duration, price, rating in one tappable card | `Service`, image URL (nullable), `VoidCallback` | Discovery grid cell |
| `ProProfileHeader` | Photo, name, specialty, rating, availability hint | `User` (staff), image URL (nullable) | Booking wizard step 2 header + future profile screen |
| `WizardShell` | Step progress indicator + title + back/next + persistent footer | `currentStep`, `totalSteps`, `footer` widget, `onBack/onNext` | Wrapper for the new booking wizard |
| `TimeSlotPicker` | Bottom-sheet day strip + slot grid with peak/disabled states | `List<DateTime>` days, `Map<day, slots>`, selected value | Wizard step 3 body |
| `BookingSummaryCard` | Service/time/pro/calendar actions in confirmation hierarchy | `BookingSummary` | Success page hero (replaces 88px green check) |
| `BrandedEmptyState` | Monogram/illustration + title + subtitle + action | Existing `EmptyStateWidget` contract (superset) | Replaces generic empty states page by page |
| `AppErrorBanner` | Icon + message + retry action (never color-alone) | `message`, `onRetry?` | Replaces scattered red `Text(_error)` (audit item #3) |
| `TenantHero` | Logo, business name, tagline block | `Business` (nullable → RestoraHub fallback) | Login/registration brand moment |

`TenantBrandHeader` stays as the drawer/app-bar identity; `TenantHero` is its large-format sibling, not a replacement.

## 6. Typography & color (pilot values; tenants override)

- Display: Fraunces (600/700 for headings, hero numbers tabular). Body/UI: Inter (400/500/600). Loaded via `google_fonts`, applied in `buildThemeData` so every `textTheme` consumer inherits.
- Light: warm paper surface (`#FAF7F2`-family derived from seed harmonization), ink on-surface, seed accent. Dark: true dark surface with seed-tinted containers (existing `fromSeed` pipeline). Status colors unchanged (merged semantic roles).
- Radius: 12dp cards (already standardized), 20dp sheets, full-round chips/avatars. Elevation: restrained (0–1dp surfaces, 2dp dialogs).

## 7. Imagery contract

- `Service.imageUrl`, staff `photoUrl` resolved via existing models if present, else nullable path → monogram fallback. No schema change in this spec: if model fields are absent, units accept explicit `imageUrl` params and repositories are wired in a later sub-project.
- `cached_network_image` with shimmer placeholder + error→monogram. Offline: monogram, never broken-image icon.

## 8. Motion contract

- Page transitions: platform default (no custom router). In-flow: `AnimatedSwitcher`/`AnimatedContainer` at 200ms `Curves.easeOut`. Confirmation: single staged reveal (summary card → actions). `MediaQuery.disableAnimations` / reduced-motion: skip orchestration, show final state.
- No animation packages. No autoplay loops.

## 9. Sub-projects (order; each gets its own plan → implementation cycle)

1. **P1 — Customer booking flow + theme tokens + image pipeline.** Fonts, palette, `premium/` library, home hero ("next appointment"), discovery grid, wizard, success, login/registration `TenantHero`. This spec covers P1.
2. **P2 — Settings/profile/receipts/notifications polish.** Apply library + tokens; no new components except where listed.
3. **P3 — Staff/admin density.** Tables, calendars, analytics keep density but inherit type/color/motion; no layout rewrites.

## 10. Dependencies (approved 2026-09-25)

- `google_fonts` (font delivery, no asset bundling, offline fallback to system fonts).
- `cached_network_image` (photo pipeline with placeholder/error states).
Justification: Flutter-standard answers for the two gaps stock SDK cannot fill (font files, image caching); no backend, no keys, no paid services. All else stock Flutter.

## 11. Constraints (binding on all sub-projects)

- `flutter test` green and `flutter analyze` 0 issues after every task (current: 397/397).
- Additive only; tenant isolation and role boundaries respected; pilot data untouched.
- l10n: reuse keys; new strings get English fallback inline per existing pattern.
- Accessibility floor: 44dp targets, semantic labels on icon buttons, errors never color-alone, contrast 4.5:1 body text.
- No commits to `.kilo/`; plans under `docs/superpowers/plans/`.

## 12. Success criteria (P1)

- A first-time user can name the brand, find a service with a photo, pick a pro with a face, choose a time, and confirm — without reading instructions.
- Screenshots of home/discovery/wizard/success are unrecognizable as stock Material, yet every control behaves like the platform users already know.
- Light + dark + rose/indigo tenants render with zero hardcoded-color breakage (strict grep gate).
