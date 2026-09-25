# Theme Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Centralize RestoraHub's visual identity in the theme layer so all 25 pages share one text, card, input, and color language, with zero hardcoded `Colors.*` outside semantic helpers.

**Architecture:** Extend the existing `ThemeHelper.generateTenantTheme` (single construction site) with text/card/input/appbar themes, add a `SemanticColorHelper` beside `StatusColorHelper`, and delegate `ThemeProvider._buildTheme` to the shared builder so tenant and app themes cannot drift. Additive only: no existing API changes, no new packages.

**Tech Stack:** Flutter Material 3 (`ColorScheme.fromSeed`, `ThemeData`), flutter_test, existing l10n fallbacks untouched.

**Spec:** Design audit 2026-09-25 (items #1, #2, #4): theme is seed-color only (`lib/theme/theme_helper.dart:19-26`), 65 hardcoded `Colors.*` in ~15 files, skeleton breaks dark mode (`lib/widgets/appointment_card_skeleton.dart:9-10`).

## Global Constraints

- `flutter test` must stay 391/391 passing after every task.
- `flutter analyze` must report 0 issues after every task.
- Additive only: existing `ThemeHelper`/`ThemeProvider` public APIs keep working; `fromMap()` defaults untouched.
- No new dependencies.
- Tenant isolation respected: tenant theme still derives from `BusinessBranding.primaryColor` with teal `#008080` fallback.
- Do NOT commit unless the user explicitly requests it; end tasks with verification, not `git commit`.

---

## File Structure

- Modify: `lib/theme/theme_helper.dart` — add text/card/input/appbar themes + shared `buildThemeData()` used by both tenant and app themes.
- Modify: `lib/providers/theme_provider.dart` — delegate `_buildTheme` to `ThemeHelper`, keep per-`AppTheme` surface/onSurface overrides.
- Create: `lib/helpers/semantic_color_helper.dart` — error/success/info/warning surfaces from `ColorScheme` (mirrors `StatusColorHelper` pattern).
- Modify: hardcoded call sites (errors → `scheme.error`, skeleton → scheme roles, calendar/notification/analytics colors → semantic helper).
- Modify: `lib/widgets/charts/service_category_pie_chart.dart` — palette derived from `ColorScheme` instead of raw `Colors.blue/green/red/teal/amber`.
- Test: `test/theme/theme_helper_test.dart` (extend), create `test/helpers/semantic_color_helper_test.dart`.

---

### Task 1: Centralize text, card, input, and app bar themes in ThemeHelper

**Files:**
- Modify: `lib/theme/theme_helper.dart:19-26`
- Test: `test/theme/theme_helper_test.dart`

**Interfaces:**
- Consumes: existing `generateTenantTheme(BusinessBranding?, {isDark})`, `_buildChipTheme`, `_buildElevatedButtonTheme`, `_buildTabBarTheme`.
- Produces: `ThemeHelper.buildThemeData({required Color seedColor, required Brightness brightness, Color? surface, Color? onSurface})` returning fully-populated `ThemeData` (colorScheme, textTheme, cardTheme, inputDecorationTheme, appBarTheme, chip/elevated/tab themes). Later tasks call this instead of hand-rolling styles.

- [ ] **Step 1: Write the failing test**

```dart
test('applies shared card, input, and app bar themes', () {
  final theme = ThemeHelper.generateTenantTheme(
    BusinessBranding(primaryColor: '#008080'),
  );

  expect(theme.cardTheme.margin, const EdgeInsets.only(bottom: 12));
  expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
  expect(theme.appBarTheme.centerTitle, isFalse);
  expect(theme.textTheme.bodyMedium?.fontSize, 14);
});
```

Append to the existing `group('ThemeHelper', ...)` in `test/theme/theme_helper_test.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/theme_helper_test.dart`
Expected: FAIL — `cardTheme.margin` is null (no cardTheme configured yet).

- [ ] **Step 3: Write minimal implementation**

In `lib/theme/theme_helper.dart`, extract a shared builder and wire the missing themes (keep every existing builder untouched):

```dart
static ThemeData buildThemeData({
  required Color seedColor,
  required Brightness brightness,
  Color? surface,
  Color? onSurface,
}) {
  var colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  if (surface != null || onSurface != null) {
    colorScheme = colorScheme.copyWith(surface: surface, onSurface: onSurface);
  }
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    appBarTheme: AppBarTheme(centerTitle: false),
    textTheme: Typography.material2021().black.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
    chipTheme: _buildChipTheme(colorScheme),
    elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
    tabBarTheme: _buildTabBarTheme(colorScheme),
  );
}
```

Then make `generateTenantTheme` delegate to it:

```dart
static ThemeData generateTenantTheme(BusinessBranding? branding,
    {bool isDark = false}) {
  final seedColor =
      _parseHexColor(branding?.primaryColor) ?? _defaultPrimaryColor;
  final brightness = _resolveBrightness(branding?.themeMode, isDark);
  return buildThemeData(seedColor: seedColor, brightness: brightness);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/theme/theme_helper_test.dart`
Expected: all PASS (existing 85-line suite plus the new test).

- [ ] **Step 5: Run full gates**

Run: `flutter analyze` (expect: No issues found) and `flutter test` (expect: All tests passed, 392/392).

---

### Task 2: Delegate ThemeProvider to the shared builder (remove drift)

**Files:**
- Modify: `lib/providers/theme_provider.dart:54-75`

**Interfaces:**
- Consumes: `ThemeHelper.buildThemeData` from Task 1.
- Produces: identical `ThemeProvider.theme` output for all four `AppTheme` values (no visual change; pure delegation).

- [ ] **Step 1: Write the failing test**

Create `test/providers/theme_provider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('all AppTheme values produce identical output to shared builder', () {
      final provider = ThemeProvider();
      for (final appTheme in AppTheme.values) {
        provider.setTheme(appTheme);
        expect(provider.theme.colorScheme, isNotNull);
        expect(provider.theme.cardTheme.margin,
            const EdgeInsets.only(bottom: 12));
      }
    });

    test('dark theme uses dark brightness with indigo seed', () {
      final provider = ThemeProvider();
      provider.setTheme(AppTheme.dark);
      expect(provider.theme.brightness, Brightness.dark);
      expect(provider.theme.scaffoldBackgroundColor, const Color(0xFF121212));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/theme_provider_test.dart`
Expected: FAIL — `cardTheme.margin` is null because `ThemeProvider._buildTheme` does not set a cardTheme yet.

- [ ] **Step 3: Write minimal implementation**

Replace `ThemeProvider._buildTheme` body with delegation (keep the per-theme surface/onSurface overrides exactly as they are):

```dart
import '../theme/theme_helper.dart';

ThemeData _buildTheme({
  required Color seedColor,
  required Brightness brightness,
  Color? surface,
  Color? onSurface,
}) {
  return ThemeHelper.buildThemeData(
    seedColor: seedColor,
    brightness: brightness,
    surface: surface,
    onSurface: onSurface,
  );
}
```

Delete the now-duplicated `_buildChipTheme`, `_buildElevatedButtonTheme`, `_buildTabBarTheme` private methods from `theme_provider.dart` (they live in `ThemeHelper`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/providers/theme_provider_test.dart test/theme/theme_helper_test.dart`
Expected: all PASS.

- [ ] **Step 5: Run full gates**

Run: `flutter analyze` (expect: No issues found) and `flutter test` (expect: All tests passed).

---

### Task 3: SemanticColorHelper + migrate error/success/info call sites

**Files:**
- Create: `lib/helpers/semantic_color_helper.dart`
- Test: `test/helpers/semantic_color_helper_test.dart`
- Modify (errors → `scheme.error`): `lib/pages/login_page.dart:93`, `lib/pages/booking_page.dart:1078`, `lib/pages/registration_page.dart:189`, `lib/pages/forgot_password_page.dart:72`, `lib/pages/profile_page.dart:638`, `lib/helpers/appointment_actions.dart:43,208`, `lib/widgets/appointment_card.dart:197,204`, `lib/widgets/app_drawer.dart:52`, `lib/pages/professional_manual_booking_page.dart:206`
- Modify (status calendars/notifications/analytics → helper): `lib/pages/admin_calendar_page.dart:232,237,710-717`, `lib/widgets/professional_calendar_view.dart:476-490`, `lib/pages/notifications_page.dart:130-138`, `lib/pages/analytics_page.dart:445-452`, `lib/pages/analytics_dashboard_page.dart:145,152`, `lib/pages/settings_page.dart:139,168`, `lib/pages/success_page.dart:76`

**Interfaces:**
- Consumes: `ColorScheme` only (same contract as `StatusColorHelper.forStatus`).
- Produces: `SemanticColorHelper.errorOf(ColorScheme)`, `.successOf(ColorScheme)`, `.infoOf(ColorScheme)`, `.warningOf(ColorScheme)` — later tasks (charts, skeleton) use these.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/helpers/semantic_color_helper.dart';

void main() {
  group('SemanticColorHelper', () {
    test('maps roles to color scheme without hardcoded colors', () {
      const scheme = ColorScheme.light();
      expect(SemanticColorHelper.errorOf(scheme), scheme.error);
      expect(SemanticColorHelper.successOf(scheme), scheme.secondary);
      expect(SemanticColorHelper.infoOf(scheme), scheme.primary);
      expect(SemanticColorHelper.warningOf(scheme), scheme.tertiary);
    });

    test('dark scheme resolves to dark roles, not hardcoded values', () {
      const scheme = ColorScheme.dark();
      expect(SemanticColorHelper.errorOf(scheme), scheme.error);
      expect(SemanticColorHelper.successOf(scheme), isNot(Colors.green));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/helpers/semantic_color_helper_test.dart`
Expected: FAIL with "file not found" (helper does not exist yet).

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

/// Semantic surfaces derived from [ColorScheme] roles so white-label
/// themes recolor feedback automatically; never hardcode
/// Colors.red/green/blue/amber at call sites.
class SemanticColorHelper {
  static Color errorOf(ColorScheme scheme) => scheme.error;
  static Color successOf(ColorScheme scheme) => scheme.secondary;
  static Color infoOf(ColorScheme scheme) => scheme.primary;
  static Color warningOf(ColorScheme scheme) => scheme.tertiary;
}
```

Then migrate each listed call site, e.g. `login_page.dart:93`:

```dart
// before
style: const TextStyle(color: Colors.red),
// after
style: TextStyle(color: Theme.of(context).colorScheme.error),
```

and `success_page.dart:76`:

```dart
// before
const Icon(Icons.check_circle, size: 88, color: Colors.green),
// after
Icon(Icons.check_circle,
    size: 88, color: Theme.of(context).colorScheme.secondary),
```

Migrate one file at a time; keep diffs reviewable. Do NOT change layout, copy, or widget structure — color swap only.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/helpers/semantic_color_helper_test.dart`
Expected: PASS. Then `flutter test test/widgets/` to catch golden/behavioral regressions.

- [ ] **Step 5: Run full gates**

Run: `flutter analyze` (expect: No issues found), `flutter test` (expect: All tests passed), and `grep Colors\.(red|green|blue|amber|teal) lib/` to confirm the only remaining hits are inside `semantic_color_helper.dart` tests or `ColorScheme` constructors.

---

### Task 4: Dark-mode-safe skeleton + scheme-derived chart palette

**Files:**
- Modify: `lib/widgets/appointment_card_skeleton.dart:9-10,75-76,81`
- Modify: `lib/widgets/charts/service_category_pie_chart.dart:27-33`
- Modify: `lib/widgets/charts/revenue_trend_chart.dart:96,106,110`
- Modify: `lib/pages/analytics_dashboard_page.dart:178,185,213,277,286`, `lib/pages/analytics_page.dart:311,320,358`

**Interfaces:**
- Consumes: `SemanticColorHelper` (Task 3) + `Theme.of(context).colorScheme`.
- Produces: skeleton and charts that render correctly in light AND dark tenants with no hardcoded greys.

- [ ] **Step 1: Write the failing test**

Append to `test/widgets/` a new `appointment_card_skeleton_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restorahub/widgets/appointment_card_skeleton.dart';

void main() {
  group('AppointmentCardSkeleton', () {
    testWidgets('uses scheme roles instead of hardcoded grey',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppointmentCardSkeleton()),
        ),
      );
      expect(find.byType(AppointmentCardSkeleton), findsOneWidget);
    });
  });
}
```

(This is a smoke scaffold; the real assertion is the code change below plus manual dark-mode check in Step 5.)

- [ ] **Step 2: Run test to verify it passes as scaffold**

Run: `flutter test test/widgets/appointment_card_skeleton_test.dart`
Expected: PASS (widget builds). The "failure" this task fixes is visual: hardcoded `Colors.grey[300]/grey[100]` in dark mode.

- [ ] **Step 3: Write minimal implementation**

`skeleton` — replace hardcoded base/highlight with scheme roles:

```dart
// before
final baseColor = Colors.grey[300]!;
final highlightColor = Colors.grey[100]!;
// after
final scheme = Theme.of(context).colorScheme;
final baseColor = scheme.surfaceContainerHighest;
final highlightColor = scheme.surfaceContainerLow;
```

(`AppointmentCardSkeleton` is currently stateless-function-shaped; if it lacks `BuildContext` access at the color site, wrap the color resolution inside `build()`.)

`service_category_pie_chart.dart:27-33` — replace the raw palette:

```dart
// before
Colors.blue, Colors.green, Colors.red, Colors.teal, Colors.amber,
// after (resolve from scheme at build time)
final scheme = Theme.of(context).colorScheme;
final palette = [
  scheme.primary,
  scheme.secondary,
  scheme.tertiary,
  scheme.primaryContainer,
  scheme.secondaryContainer,
];
```

Apply the same scheme-role swap to `revenue_trend_chart.dart` (`blueGrey`/`white` → `onSurface`/`surface` roles) and the analytics pages' `Colors.grey/blueGrey/shade` usages.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets/`
Expected: all PASS.

- [ ] **Step 5: Run full gates + dark-mode eyeball check**

Run: `flutter analyze` (expect: No issues found) and `flutter test` (expect: All tests passed). Then run the app with a dark tenant (`themeMode: 'dark'`) and confirm skeleton shimmer and charts are visible with no washed-out greys.

---

## Self-Review

**1. Spec coverage:** Audit items #1 (hardcoded colors → Tasks 3, 4), #2 (skeleton dark mode → Task 4), #4 (theme centralization → Tasks 1, 2). Items #3 (shared error widget), #5–#11 (login hero, success page, card hierarchy, semantics, copy, motion) are explicitly out of scope — follow-up plans.
**2. Placeholder scan:** every step has exact file paths, line numbers, code blocks, and commands. No TBD/TODO.
**3. Type consistency:** `buildThemeData` signature is identical in Task 1 (definition) and Task 2 (call). `SemanticColorHelper` method names match between Task 3 (definition) and Task 4 (consumption).
