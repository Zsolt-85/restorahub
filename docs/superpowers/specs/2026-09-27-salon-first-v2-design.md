# Salon-First v2 — Design Spec

**Date:** 2026-09-27
**Status:** Proposed (awaiting user review; no implementation until approved)
**Approach:** A — salon-first reshell (approved 2026-09-27). Rejected: B full rebuild (3× cost, re-proven edge cases), C reskin-only (disproven by P1 preview).
**Prime directive:** RESTORE by MAYA runs its daily business on this app. Multi-business expansion is prio 2 — the tenant machinery stays intact underneath, but no SaaS chrome leaks into the salon experience.

## 1. Problem

P1 delivered premium components, but the app still feels like booking *software* instead of *MAYA's salon*:
- No default universe: first run shows platform chrome (business picking / setup wizard paths) instead of the salon.
- Navigation is drawer + FAB + AppBar titles — 2000s admin-tool shape, not a modern client app.
- Zero photography: every card falls back to monograms; the mockup's 50% (imagery) is missing.
- Copy is system-voiced ("Booking confirmed!", "Failed to load appointment details").
- `docs/user-manual.md` describes the old app screen-by-screen and is now wrong in at least: home, booking, success, login.

## 2. Goals

1. Opening the app feels like walking into MAYA's salon: her brand, her services with photos, her team with faces, in under two taps to booking.
2. Bottom-tab customer shell (Home / Book / Visits / Profile) with platform-correct back behavior.
3. Every brand choice (colors, fonts, photos, name, tagline, hours) tweakable in ONE place with a documented backup workflow.
4. Warm, plain, active-voice copy everywhere a customer looks; manual rewritten to match.
5. Smooth: transitions, staggered entrances, image fade-ins, confirm haptic — all reduced-motion gated.
6. Prio-2 safety: no provider/repository contract changes; tenant switching, super-admin, and setup wizard keep working via explicit routes.

## 3. Non-goals

- No Firestore schema changes; no model field changes (photo catalog is bundled assets + explicit params, same as P1).
- No staff/admin screen redesign (their P3 cycle stays parked).
- No new packages (haptics = stock `HapticFeedback`; images = bundled assets, no network dependency).
- No pricing/checkout changes; no notification-content changes beyond copy voice.

## 4. App shell & navigation

- Customers get `Scaffold(bottomNavigationBar: NavigationBar)` with 4 destinations: Home (`user_home_page`, hero-first), Book (`booking_page` wizard at step 0), Visits (upcoming+history — extract the existing tab content into this destination), Profile (existing `profile_page` + settings entry + logout).
- Back button from any tab returns to Home; back on Home exits (no login bounce for authenticated users — existing `route_guard_helper` behavior preserved, verified by test).
- Staff/admin roles keep the existing drawer shell untouched.
- Deep-linkable tab index via existing route arguments pattern (`Routes` constants; add `home`, `visits` tab keys — additive constants only).

## 5. MAYA-first boot

- New `lib/config/salon_config.dart`: `const defaultBusinessId = '...'` (MAYA's id, filled at implementation from Firestore/console — exact value recorded in the plan), plus `setupRoute`, `adminRoute` constants.
- Startup resolution (in the existing post-auth routing, same file that reads `currentBusiness` today): if user has no business and no explicit deep link → load default business id instead of setup/business-pick. Super-admin users bypass to dashboard (existing role check first).
- Setup wizard + business onboarding remain fully reachable at their current routes; nothing deleted.

## 6. Photo catalog

- `assets/images/stock/`: ~10 bundled spa/salon photos (massage, facial, nails, hair, stones, salon interior, 2–3 staff portraits, 1 hero). Sourced at implementation time from Unsplash (license permits app use); exact filenames recorded in the plan. Declared in `pubspec.yaml` assets.
- `lib/config/photo_catalog.dart`: `photoForService(String serviceName)` keyword map + `staffAvatar(int index)` rotation + `heroImage()`; pure functions, unit-tested.
- `BrandImage` gains optional `catalogKey` param (falls back to current `imageUrl` → monogram chain; signature additive only).
- Service wizard/discovery passes `photoForService(...)`; pro rows pass `staffAvatar(...)`; home hero passes `heroImage()`. When brand JSON (Ingredient 7) supplies URL overrides, catalog returns those instead (network path via existing `CachedNetworkImage`).

## 7. Brand config (the tweak backup)

- `assets/brand/maya.json` (committed): `{ "businessId", "displayName", "tagline", "seedColor", "displayFont", "bodyFont", "photoOverrides": {catalogKey: url}, "hours", "address", "phone" }`. All fields optional; missing → compiled-in defaults identical to today's values.
- `lib/config/brand_config.dart`: loads JSON at startup (rootBundle, cached), exposes typed getters with defaults; `ThemeHelper` reads `seedColor`/`displayFont`/`bodyFont` from it when no tenant branding overrides (tenant `BusinessBranding` still wins when present — prio-2 path intact).
- Manual documents the tweak workflow: edit JSON → hot restart → verify; JSON is the backup (git-tracked, copyable per future tenant).

## 8. Copy voice + manual

- Voice rules (binding): warm, plain, active; name the outcome ("Your glow is booked for tomorrow at 10:30"); errors say what happened + one next step ("We couldn't reach the calendar — check connection and retry"); never blame, never jargon (`webhook`, `slot`, `provider` banned from customer strings).
- Rewrite scope: home, wizard steps, success, auth, empty states, error banners, notifications page strings, confirm dialogs (customer paths). Staff/admin strings untouched. Existing l10n keys reused where meaning matches; new keys added with English fallback per pattern (the P1 `'See you soon'` key debt is folded into this pass).
- `docs/user-manual.md`: rewritten screen-for-screen (install → login → home → book → visits → profile → settings), with the brand-tweak workflow as its own chapter.

## 9. Smoothness contract

- Tab switches: `AnimatedSwitcher` fade (150ms, `easeOut`).
- Lists (services grid, slots, upcoming): one-shot staggered entrance — `AnimatedOpacity` + `SlideTransition` offset (0,8px)→0, 150ms, delay `index*30ms` capped at 5 items; plays once per screen appearance (not on scroll).
- Images: `CachedNetworkImage.fadeInDuration 200ms` (bundled assets decode instantly; network overrides fade).
- Confirm success: `HapticFeedback.lightImpact()` on booking confirm + success reveal (existing).
- All gated behind `MediaQuery.disableAnimations` (final state, zero duration). No packages.

## 10. Constraints (binding)

- `flutter test` green + `flutter analyze` 0 issues after every task (current: 425 passed + 1 skipped).
- No provider/repository/model/schema/route-removal changes; additive navigation constants only.
- Tenant isolation + role boundaries intact; MAYA default never leaks into another business's data (default applies only when user has NO business).
- Pilot data untouched. No new dependencies. No commits to `.kilo/`.

## 11. Success criteria

- Cold start to booking confirmation for a returning MAYA customer: ≤ 4 taps, every screen visibly branded, every service/pro with a photo.
- The app is unrecognizable as stock Material next to the P1 build, yet all 425+ tests still pass unmodified in behavior.
- A non-technical owner can re-tweak brand (color/font/photo/hours) using only the manual's chapter + the JSON backup.
- Prio-2 intact: switching `defaultBusinessId` off / logging in as super-admin still reaches multi-business tooling.
