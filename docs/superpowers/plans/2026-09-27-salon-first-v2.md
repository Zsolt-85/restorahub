# Salon-First v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** MAYA's salon runs its day on this app — bottom-tab customer shell, MAYA-first boot, bundled photo catalog, one-file brand config, rewritten copy + manual, quiet motion — with multi-business machinery intact underneath.

**Architecture:** New shell + config + catalog layers sit beside existing code: `CustomerShell` composes existing pages (no page rewrites), `SalonConfig`/`BrandConfig` are pure config with compiled-in defaults (null/absent → today's behavior), `photo_catalog.dart` is pure functions over bundled assets, `BrandImage.catalogKey` extends the existing fallback chain. Route guard extended additively; providers/repos/models/schemas untouched.

**Tech Stack:** Flutter Material 3, stock motion/haptics (`HapticFeedback`), bundled JPG assets, rootBundle JSON, existing providers. Zero new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-27-salon-first-v2-design.md` (§4–9).

## GlobalConstraints

- `flutter test` green after every task (baseline: verify count with `flutter test` before Task 1; currently 425 passed + 1 skipped).
- `flutter analyze` 0 issues after every task.
- No provider/repository/model/schema changes; no route removals; additive route constants only; no new packages.
- Tenant isolation intact: MAYA default applies ONLY when the user has no business; super-admin path unchanged and tested.
- l10n: new keys with inline English fallback per existing pattern.
- Accessibility floor: 44dp targets, semantics on icon buttons, errors never color-alone, reduced-motion gates on all motion.
- Staged stock photos live at `C:\Users\maias\AppData\Local\Temp\opencode\stock\` (12 verified JPGs, ~856KB) — Task 2 moves them into the repo; do not hotlink.
- Do NOT commit unless the user explicitly requests it; end tasks with verification, not `git commit`.

---

## File Structure

- Create `lib/config/`: `salon_config.dart` (default business id, nullable), `brand_config.dart` (JSON loader + typed getters), `photo_catalog.dart` (pure mappings).
- Create `assets/brand/maya.json`, `assets/images/stock/*.jpg` (12), `assets/images/stock/ATTRIBUTION.md`.
- Create `lib/pages/customer_shell.dart`, `lib/pages/visits_page.dart`.
- Modify: `pubspec.yaml` (assets only), `lib/helpers/route_guard_helper.dart` (default-business branch), `lib/main.dart` (`buildRouteWidget` + 1 shell case), `lib/constants/routes.dart` (additive), `lib/widgets/premium/brand_image.dart` (`catalogKey` additive param), customer copy strings (Task 6 list), `docs/user-manual.md` (rewrite).
- Test: `test/config/` (3 new), `test/widgets/customer_shell_test.dart`, `test/widgets/visits_page_test.dart`, extend `test/helpers/route_guard_helper_test.dart` + `test/unit/route_table_test.dart`.

---

### Task 1: Brand config + salon config (no behavior change)

**Files:**
- Create: `lib/config/salon_config.dart`, `lib/config/brand_config.dart`, `assets/brand/maya.json`
- Test: `test/config/salon_config_test.dart`, `test/config/brand_config_test.dart`

**Interfaces:**
- Consumes: nothing (standalone pure config).
- Produces: `SalonConfig.defaultBusinessId` (`String?`, null = today's behavior), `BrandConfig.load({AssetBundle? bundle})` → `BrandConfig` with getters `displayName` (default `'RestoraHub'`), `tagline` (default `'Beauty & wellness bookings'`), `seedColorHex` (default `'#2F5D50'`), `displayFont` (default `'Fraunces'`), `bodyFont` (default `'Inter'`), `photoOverride(String key)` (nullable), `address`, `phone`, `hours` (all nullable). Later tasks consume these verbatim.

- [ ] **Step 1: Write the failing tests**

```dart
// test/config/brand_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/brand_config.dart';

void main() {
  group('BrandConfig', () {
    test('defaults apply when JSON is absent', () async {
      final config = await BrandConfig.load(jsonString: null);
      expect(config.displayName, 'RestoraHub');
      expect(config.seedColorHex, '#2F5D50');
      expect(config.displayFont, 'Fraunces');
      expect(config.bodyFont, 'Inter');
      expect(config.photoOverride('massage'), isNull);
    });

    test('JSON values override defaults', () async {
      final config = await BrandConfig.load(
        jsonString:
            '{"displayName":"Restore by Maya","seedColor":"#6B3F2A"}',
      );
      expect(config.displayName, 'Restore by Maya');
      expect(config.seedColorHex, '#6B3F2A');
      expect(config.bodyFont, 'Inter');
    });

    test('malformed JSON falls back to defaults, never throws', () async {
      final config = await BrandConfig.load(jsonString: '{oops');
      expect(config.displayName, 'RestoraHub');
    });
  });
}
```

```dart
// test/config/salon_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/salon_config.dart';

void main() {
  test('default business id is null until configured', () {
    expect(SalonConfig.defaultBusinessId, isNull);
  });
}
```

`BrandConfig.load` signature: `static Future<BrandConfig> load({String? jsonString, AssetBundle? bundle})` — if `jsonString` given use it (tests), else load `assets/brand/maya.json` via bundle/rootBundle, else defaults. `SalonConfig.defaultBusinessId`: `static const String? defaultBusinessId = null;` with a comment recording that MAYA's id is filled when known (nullable = current behavior preserved).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/config/`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Write minimal implementation**

`assets/brand/maya.json` (committed backup to tweak):
```json
{
  "businessId": null,
  "displayName": "Restore by Maya",
  "tagline": "Beauty & wellness bookings",
  "seedColor": "#2F5D50",
  "displayFont": "Fraunces",
  "bodyFont": "Inter",
  "address": "Main St 12",
  "phone": null,
  "hours": null,
  "photoOverrides": {}
}
```

`lib/config/brand_config.dart`: `dart:convert` JSON parse in try/catch → defaults; typed getters as specified. `lib/config/salon_config.dart`: class with `static const String? defaultBusinessId = null;` + `static const setupRoute = '/setup_wizard';` (reuse `Routes.setupWizard` instead — do NOT duplicate; import routes and expose nothing new. Final shape: only `defaultBusinessId` + doc comment.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/config/`
Expected: all PASS (4/4).

- [ ] **Step 5: Run full gates**

Run: `flutter analyze` (expect: No issues found) and `flutter test` (expect: All tests passed).

---

### Task 2: Photo catalog + BrandImage catalogKey

**Files:**
- Create: `assets/images/stock/*.jpg` (12, copied from staging), `assets/images/stock/ATTRIBUTION.md`, `lib/config/photo_catalog.dart`
- Modify: `pubspec.yaml` (assets block), `lib/widgets/premium/brand_image.dart` (additive `catalogKey`)
- Test: `test/config/photo_catalog_test.dart`

**Interfaces:**
- Consumes: `BrandConfig.photoOverride` (Task 1).
- Produces: `photoForService(String serviceName)` → asset path, `staffAvatar(int index)` → asset path (rotates 3 portraits), `heroImage()` → asset path. Later tasks consume verbatim. `BrandImage` gains `final String? catalogKey` (resolved before `imageUrl`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/config/photo_catalog.dart';

void main() {
  group('photo catalog', () {
    test('massage names map to massage photo', () {
      expect(photoForService('Swedish Massage'), contains('massage-deep-tissue'));
      expect(photoForService('HOT STONE therapy'), contains('massage'));
    });

    test('facial, nails, hair map to their photos', () {
      expect(photoForService('HydraFacial'), contains('facial'));
      expect(photoForService('Gel Manicure'), contains('nails'));
      expect(photoForService('Balayage'), contains('hair'));
    });

    test('unknown service falls back to hero still-life', () {
      expect(photoForService('Quantum Alignment'), contains('hero-spa-still-life'));
    });

    test('staff avatars rotate deterministically', () {
      expect(staffAvatar(0), contains('staff-elena'));
      expect(staffAvatar(3), staffAvatar(0));
    });

    test('hero image is the still-life', () {
      expect(heroImage(), contains('hero-spa-still-life'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/config/photo_catalog_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Write minimal implementation**

Copy the 12 staged JPGs from `C:\Users\maias\AppData\Local\Temp\opencode\stock\` to `assets/images/stock/` with EXACT names: `massage-deep-tissue.jpg`, `hero-spa-still-life.jpg`, `facial-hydra.jpg`, `facial-acupuncture.jpg`, `nails-gel.jpg`, `hair-stylist-work.jpg`, `salon-interior.jpg`, `aromatherapy-oils.jpg`, `serum-editorial.jpg`, `staff-elena.jpg`, `staff-sofia.jpg`, `staff-ana.jpg`. Verify byte counts match staging (report both). Write `ATTRIBUTION.md` listing each file + `https://unsplash.com` source + "Unsplash License — free for commercial use, no attribution required."

`pubspec.yaml` flutter section: add
```yaml
  assets:
    - assets/images/stock/
    - assets/brand/maya.json
    - assets/fonts/
```
(merge with existing assets if present — read the section first; keep fonts working.)

`lib/config/photo_catalog.dart`:
```dart
const _massage = 'assets/images/stock/massage-deep-tissue.jpg';
const _hero = 'assets/images/stock/hero-spa-still-life.jpg';
const _facial = 'assets/images/stock/facial-hydra.jpg';
const _nails = 'assets/images/stock/nails-gel.jpg';
const _hair = 'assets/images/stock/hair-stylist-work.jpg';

const _staff = [
  'assets/images/stock/staff-elena.jpg',
  'assets/images/stock/staff-sofia.jpg',
  'assets/images/stock/staff-ana.jpg',
];

String photoForService(String serviceName) {
  final s = serviceName.toLowerCase();
  if (s.contains('massag') || s.contains('stone')) return _massage;
  if (s.contains('facial') || s.contains('skin') || s.contains('peel')) return _facial;
  if (s.contains('nail') || s.contains('manicure') || s.contains('pedicure')) return _nails;
  if (s.contains('hair') || s.contains('cut') || s.contains('color') || s.contains('balayage')) return _hair;
  if (s.contains('aroma') || s.contains('oil')) {
    return 'assets/images/stock/aromatherapy-oils.jpg';
  }
  return _hero;
}

String staffAvatar(int index) => _staff[index % _staff.length];

String heroImage() => _hero;
```

`BrandImage`: add `final String? catalogKey;` + constructor param (default null); resolution order: explicit `catalogKey` asset path (if it starts with `assets/`, render via `Image.asset` with same placeholder/error chain) → `imageUrl` (existing) → monogram. For asset rendering, branch BEFORE `CachedNetworkImage`:
```dart
if (catalogKey != null && catalogKey!.startsWith('assets/')) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Image.asset(
      catalogKey!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, _, __) => MonogramTile(...same as existing...),
    ),
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/config/ test/widgets/premium/brand_image_test.dart`
Expected: all PASS (existing brand_image tests unaffected — constructor additive).

- [ ] **Step 5: Run full gates**

Run: `flutter analyze` (expect: No issues found) and `flutter test` (expect: All tests passed).

---

### Task 3: MAYA-first boot (route guard extension)

**Files:**
- Modify: `lib/helpers/route_guard_helper.dart`, `lib/providers/business_provider.dart` ONLY if a load-by-id method is missing (check: `businessRepo.getBusinessById` + `businessProvider.setBusiness` already exist per main.dart:121-126 — reuse, do not add)
- Test: extend `test/helpers/route_guard_helper_test.dart`, `test/unit/route_table_test.dart`

**Interfaces:**
- Consumes: `SalonConfig.defaultBusinessId` (Task 1), existing `BusinessRepository.getBusinessById` + `BusinessProvider.setBusiness`.
- Produces: default-resolution behavior (no new API).

- [ ] **Step 1: Read the guard + its tests fully.** Read `lib/helpers/route_guard_helper.dart`, `test/helpers/route_guard_helper_test.dart`, `test/unit/route_table_test.dart`, and `main.dart:112-131` (existing business-load block).
- [ ] **Step 2: Write the failing tests.** Add cases: (a) customer with NO businessId + `SalonConfig.defaultBusinessId` null → today's behavior unchanged (setup/login path — assert current expected value, no behavior change); (b) customer with NO businessId + default id set → redirect resolves to customer home (not setup wizard), given `businessProvider` can load it. Since `defaultBusinessId` is a `static const` (null), test (b) via a seam: implement the guard branch as a pure function `resolveDefaultBusinessId({String? userBusinessId, String? configuredDefault})` returning `configuredDefault` iff user id null/empty, else user id — unit-test THAT directly (3 cases: user id wins, default fills gap, both null → null).
- [ ] **Step 3: Implement.** Add the pure function + wire it into the existing no-business branch: where the guard currently sends business-less users to setup, first resolve `resolveDefaultBusinessId(userBusinessId: user.businessId, configuredDefault: SalonConfig.defaultBusinessId)`; if non-null AND different from current behavior path, load via existing repo+setter (mirror main.dart:121-126 lines inside the guard's async context — if the guard is sync, do the load at the call site that already handles async business loading; read the caller before choosing) and continue to customer home. Super-admin check stays FIRST (unchanged). If `defaultBusinessId` is null (today), zero behavior change — prove with the (a) test.
- [ ] **Step 4: Run tests.** Targeted guard suites — expect all PASS.
- [ ] **Step 5: Full gates.** `flutter analyze` + `flutter test` green.

---

### Task 4: CustomerShell + VisitsPage + routes

**Files:**
- Create: `lib/pages/customer_shell.dart`, `lib/pages/visits_page.dart`
- Modify: `lib/constants/routes.dart` (add `customerShell = '/home'`, `visits = '/visits'`), `lib/main.dart` (`buildRouteWidget` + 2 cases)
- Test: `test/widgets/customer_shell_test.dart`, `test/widgets/visits_page_test.dart`, extend route-table test for the 2 new routes

**Interfaces:**
- Consumes: existing pages as tab bodies (`UserHomePage` minus chrome problem — see below), `AppointmentProvider.upcomingAppointments`/`pastAppointments`, `AppointmentCard`, `BrandedEmptyState`.
- Produces: `CustomerShell({int initialIndex = 0})`, `VisitsPage()` — Task 7 consumes for motion/eyeball.

Chrome problem (decided): tab pages keep their own `AppBar`s EXCEPT `UserHomePage`, whose AppBar+drawer+FAB triple would nest badly. Solution: extract the existing `_buildCustomerDashboardBody` content path — NO. Minimal correct: `CustomerShell` Home tab hosts `UserHomePage` ONLY if it accepts chrome suppression. Read `user_home_page.dart` build: if AppBar/drawer/FAB removal needs >10 lines changed there, instead set Home tab = greeting+hero+upcoming extracted into `VisitsPage`-style composition reusing `AppointmentCard` (duplicate ~40 lines from user_home sections, do NOT refactor user_home). Report which option was taken. Book tab = `BookingPage()` default constructor (verify it has one — booking_page takes optional params, so `const BookingPage()` works if const; else plain). Visits tab = new `VisitsPage` (upcoming list via `AppointmentCard` + history link to `Routes.pastAppointments`). Profile tab = existing `ProfilePage` (verify const + no required args; if it requires args, wrap with the args today's drawer passes — read the drawer call site).

Shell: `Scaffold(body: IndexedStack(index: _index, children: [...]), bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: ..., destinations: [Home, Book, Visits, Profile with icons home/calendar_today/history/person]))` + `PopScope(canPop: _index == 0, onPopInvoked: if not 0 setState 0)`. `initialIndex` respected. All labels inline English (l10n keys for nav come in Task 6 if trivially present — else inline, reported).

Tests: shell renders 4 destinations + switches body on tap + back-to-home behavior; visits shows upcoming cards + history link; route table maps `/home`→CustomerShell, `/visits`→VisitsPage.

- [ ] Steps follow TDD (tests first FAIL, implement, PASS, gates). Do NOT commit.

---

### Task 5: Photo wiring (cards, hero, pro rows)

**Files:**
- Modify: `lib/pages/booking_page.dart` (ServiceCard + ProProfileHeader call sites), `lib/pages/user_home_page.dart` (hero image), `lib/pages/success_page.dart` (pairs-well card if present, else skip + report)
- Test: existing suites must pass unchanged (photo params are additive/optional)

**Interfaces:**
- Consumes: `photoForService`, `staffAvatar`, `heroImage` (Task 2), `BrandImage.catalogKey` (Task 2).

- [ ] **Step 1: Make the swaps.** ServiceCard calls gain `imageUrl: photoForService(service.name)` — WAIT: `ServiceCard` takes `imageUrl` (network URL) not catalogKey, and catalog returns ASSET paths. Check `ServiceCard` implementation: it forwards to `BrandImage(imageUrl: ...)`, which treats non-asset strings as network URLs. Asset paths would break. Two options: (a) extend `ServiceCard`/`ProProfileHeader` with optional `catalogKey` forwarded to `BrandImage` (additive, preferred); (b) wrap asset path. Take (a): add `final String? catalogKey` to both widgets, forward to `BrandImage(catalogKey: catalogKey ?? imageUrl-resolution...)`. Define `BrandImage` precedence from Task 2: catalogKey asset → imageUrl → monogram. Update the two widgets' tests? Their signatures gain optional params — existing tests pass unchanged. Add one test each asserting catalog image renders (pump with `catalogKey: heroImage()`, expect `Image` widget present).
- Home hero: pass `catalogKey: heroImage()` into whatever hero visual exists (Task P1 hero is ink container — add a top `BrandImage` banner 140dp if none; read current hero code first, minimal insertion).
- Pro rows: `ProProfileHeader(imageUrl: null)` → add `catalogKey: staffAvatar(index)` — index source: position in `_professionals` list at build time (pass loop index; deterministic rotation).
- [ ] **Step 2: Run tests.** `flutter test test/widgets/premium/ test/widgets/booking_page_test.dart test/widgets/user_home_page_test.dart` — expect PASS.
- [ ] **Step 3: Full gates.** Analyze + full suite green.

---

### Task 6: Copy voice + l10n keys (incl. 'See you soon' debt)

**Files:**
- Modify: customer strings in `user_home_page.dart`, `booking_page.dart`, `success_page.dart`, `login_page.dart`, `registration_page.dart`, `forgot_password_page.dart`, `notifications_page.dart`, `past_appointments_page.dart`, `customer_shell.dart`, `visits_page.dart` + l10n arb/json files (find the active locale files first — check `lib/l10n/` contents and how keys are added; mirror the existing key pattern exactly)
- Test: update affected finder tests (same-behavior rationale listed)

**Interfaces:** none new (copy only).

Copy rules (binding, from spec §8): warm/plain/active; name the outcome; errors = what happened + one next step; ban `webhook/slot/provider/staffId` from customer strings. Concrete swaps (adapt exact current strings after reading each file; keep meaning, change voice):
- Greetings stay (`Good morning/afternoon/evening` + ADD l10n keys `greetingMorning/Afternoon/Evening`).
- `'Next appointment'` → key `nextAppointment`. `'See you soon'` → key `seeYouSoon`. `'Next'` footer → key `wizardNext`. `'Book Now'`/`'Book a Service'` keep keys if present.
- `'Failed to load appointment details'` → `'We couldn't load this booking — pull to retry.'` + key. `'Could not load appointments'` site → same voice + key. `'Unable to reschedule this appointment'` → `'We couldn't open rescheduling — try again.'` + key.
- Empty states: `'No upcoming appointments'`/`'Ready for your next visit?'` keep keys if present, else add `emptyUpcomingTitle/Subtitle` in-voice.
- Confirm dialogs (customer): keep decisions, warm the verbs (report each change).
- [ ] TDD: tests asserting old literals get updated finders FIRST (watch them fail), then strings change, then green. Full gates after.

---

### Task 7: Motion pass + four-config eyeball + strict gates

**Files:**
- Modify: `customer_shell.dart` (tab fade), services grid + slot grid + upcoming list (staggered entrances), `brand_image.dart` (fadeInDuration — `CachedNetworkImage(fadeInDuration: 200ms)` + `Image.asset` needs manual fade: skip asset fade, network-only per API), booking confirm (`HapticFeedback.lightImpact()` at confirm call site in `booking_page.dart` — import `flutter/services.dart` if absent), success reveal already exists (verify, don't re-touch).
- Test: no new files; suites green.

Stagger helper (new private widget inside a NEW file `lib/widgets/premium/entrance.dart` — single unit, tested): `Entrance({required int index, required Widget child})` → `TweenAnimationBuilder` opacity 0→1 + `Transform.translate(offsetY 8→0)`, 150ms, delay `min(index,5)*30ms`, skipped entirely when `MediaQuery.disableAnimations`. Test: pumps visible; disabled-animations renders instantly (assertable via `disableAnimations: true` in `MediaQuery` wrapper test).
- [ ] Implement per above (tests first for `Entrance`, eyeball for the rest).
- [ ] Eyeball 4 configs (light tenant, dark tenant, rose, indigo) via `flutter run` or widget pumps: photos/monograms correct, no whiteout, wizard transitions, tab fades, haptic point reached (code-verified). Report method + results.
- [ ] Strict gates: `grep -rn "Image.network\|CircleAvatar(child: Icon" lib/pages/user_home_page.dart lib/pages/booking_page.dart lib/pages/success_page.dart lib/pages/login_page.dart` → zero hits expected; `flutter analyze` + `flutter test` green.

---

### Task 8: Manual rewrite + brand-tweak chapter

**Files:**
- Modify: `docs/user-manual.md` (full rewrite; current 92 lines — read first)
- Test: none (docs). Verification: every screen named exists as a route/page (cross-check list in report); brand-tweak chapter steps executable in order (reviewer walkthrough).

Content: install → login → home → book (wizard steps) → visits → profile → settings → notifications; brand-tweak chapter (`assets/brand/maya.json` fields table + edit → hot restart → verify + git-backup note); FAQ (photos replaceable, dark mode, languages). Warm voice, screenshots not required (no binary assets in docs).

---

## Self-Review

**1. Spec coverage:** §4 shell/tabs/back → Task 4. §5 boot/default/super-admin intact → Task 3. §6 catalog/fallbacks/no-schema → Tasks 2, 5. §7 JSON/backup/tweak-docs → Tasks 1, 8. §8 voice/manual → Task 6, 8. §9 motion/haptics/gates → Task 7. §10 constraints → Global Constraints. §11 success criteria → Tasks 4–7 + gates.
**2. Placeholder scan:** no TBD/TODO; MAYA id resolved by nullable-default design (no blocking lookup); photo filenames exact; test code complete per task.
**3. Type consistency:** `photoForService(String)→String`, `staffAvatar(int)→String`, `heroImage()→String`, `BrandConfig.load({jsonString?, bundle?})`, getters as specified in Task 1 and consumed in Tasks 2/5; `CustomerShell({initialIndex=0})`, `VisitsPage()` consumed in Task 4 main wiring; `Entrance({index, child})` internal to Task 7.
