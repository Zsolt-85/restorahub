# RestoraHub — Master Roadmap (single source of truth)

> **This file is the ONLY tracker.** All planning, phases, and progress live here.
> Historical docs were archived to `docs/archive/` on 2026-09-13 (see §8).
> Pilot tenant: **RESTORE by MAYA** · Live: https://restorahub-2da2c.web.app
>
> **STRATEGIC FREEZE (2026-09-18): platform roadmap paused. All effort goes to
> the Salon Sprint below until the pilot earns revenue. Nothing is deleted —
> Phases 2.2+ wait untouched.**

## Current status

| Check | Status |
|---|---|
| `flutter test` | 391/391 passing (2026-09-18, Salon Sprint) |
| `flutter analyze` | 0 issues |
| Hotfix 2026-09-14 | Solo-pro booking empty: root cause was `firebase.json` missing the `indexes` key, so ALL index deploys were silent no-ops (server had 3). Fixed config, removed rejected single-field `services` entry, deployed for real (18 on server). Booking page shows load errors + Retry instead of silent empty |
| Hotfix-2 2026-09-14 | `permission-denied` on customer staff listing: `users` LIST rules can never satisfy non-admins → new PII-free `staff_directory` collection (public reads, owner/admin writes) + repo; booking/reschedule/success read it; directory published on register/profile-create/update; staff/admin `users` list grant (Phase-5 claims-gating noted); solo-staff service create/update rules; lazy directory singleton (eager fallback broke 34 tests). 19 indexes on server. 356/356 tests, 0 analyze issues |
| Hotfix-3 2026-09-14 | Legacy staff invisible (directory only written for new accounts): backfill publish on `restoreSession` (best-effort, never blocks login); service creation now stamps `category` (profile inherits creator's, admin dialog gains dropdown). Existing staff heal on next login. 356/356 tests, 0 analyze issues |
| Deploy 2026-09-24 | Hosting was stale since 8/25 (predated all phase work). Rebuilt + released current tree to https://restorahub-2da2c.web.app. Code = live again |
| Week-1 batch (2026-09-13) | `business_settings` + `earnings_report` routes restored; `firestore.rules` patched (staff role, services create, payments admin, users team edit); `Payment.businessId` added; booking watches/availability tenant-filtered; 8 new composite indexes; `SuperAdminProvider.updateBusiness` data-loss fixed |

## Salon Sprint — ship the pilot (active, started 2026-09-18)

Target: wife (solo massage pro) takes real customer bookings + records cash,
link in IG bio, **2–3 weeks**. Acceptance tester: the pro herself, in plain words.

- [ ] `S1` Bootstrap "Restore by Maya" (owner-assisted, no code): business active (wizard skipped), her account → `business_admin` + linked; services/hours entered by her in-app. Colleagues later join as staff (assisted linking for now); monetization trigger = first paying colleague, not before
- [x] `S2` Solo service creation unblocked (done 2026-09-18): profile flow no longer demands a business (unscoped services filtered to own); rules already permitted it
- [x] `S3` Money loop wired (done 2026-09-18): "Record payment" on completed unpaid cards (staff only) → add-payment → earnings entry in staff drawer section
- [x] `S4` Salon branding (done 2026-09-18): receipt/earnings share use salon name with generic fallback (defensive without provider); admin screens already role-gated. +5 tests. 391/391 tests, 0 analyze issues
- [ ] `S5` Pilot hardening week: her real bookings → fix complaints in order → IG-bio link live = DONE

## Product vision

A configurable white-label operating platform for appointment/service businesses — not "a booking app".
Booking is the first capability; the core (Business, Users, Services, Scheduling, Appointments,
Notifications, Payments, Analytics) must stay domain-free. Industry specifics ship as modules, never as
`if (businessType == ...)` in core. Tenant creation must eventually require zero code.

Principles: multi-tenancy first · configuration over customization · modules over core pollution ·
white-label by design · zero-code tenant creation · security before convenience · tests are the contract
(AGENTS.md).

## Competitor baseline (researched 2026-09-13)

| Vendor | Price shape | Lesson for us |
|---|---|---|
| Booksy | $29.99 + $20/staff, 30% Boost on first visit | Flat + all-included wins; never copy marketplace commission |
| Vagaro | $23.99/calendar + add-on sprawl ($10–$100 each) | Avoid add-on sprawl; bundle sensibly |
| Fresha | $0 + 20% new-client commission | Commission trap — expensive at volume, never do this |
| Square Appointments | $0 / $49 / $149 per location | Per-location pricing is the enterprise lever |
| SimplyBook.me | €0–€59.9 flat, white-label tiers, open API | Model for our white-label + flat pricing |
| Acuity / Setmore | $5–$49 flat | Simplicity benchmark for solo/small teams |

**Fair-monetization rule:** flat per-business plan pricing, unlimited bookings, **0% platform commission**,
Stripe processing passed through at cost, client data always self-serve exportable.

---

## Phase 0 — Guardrails ✅ DONE (2026-09-13)

- [x] `0.1` Green build: 277/277 tests, 0 analyze issues
- [x] `0.2` Week-1 critical fixes merged (routes, rules, tenant filters, indexes, provider fix)
- [x] `0.3` Add CI (`.github/workflows/ci.yml`: analyze + test on push/PR to main) — done 2026-09-14
- [x] `0.4` Deploy `firestore:rules` + `firestore:indexes` (2026-09-14, project `restorahub-2da2c`; no staging project exists so prod received the reviewed rules directly; 3 unused-function warnings only) — smoke-test as `staff` still open, needs running app

## Phase 1 — Functional correctness (make everything that exists actually work)

Each item: fix → fake-repo test → rules/index check. Do in order.

- [x] `1.1` Routes (done 2026-09-14): `buildRouteWidget` extracted from `MyApp` for testability; `test/unit/route_table_test.dart` covers all 21 static routes + arg shapes + unknown→login fallback + drawer→Business Settings tap test; guard tests for `businessSettings`/`earningsReport`; `analytics` (staff personal) vs `analyticsDashboard` (admin, FeatureGate) documented in `routes.dart`. 287/287 tests, 0 analyze issues
- [x] `1.2` Auth/roles (done 2026-09-14): `User.normalizeRole` choke point, used by `register()`+`createProfile()` (also fixed customers inheriting `specialty` as category); `roleEnum` in route guard, appointment provider (3×), `main.dart`; transient-null fix (assigned-but-unloaded business no longer yanks admins to wizard; login behavior unchanged); role×route matrix tests incl. legacy-`professional` parity. 296/296 tests, 0 analyze issues. Deferred (exact-match, no legacy variant): page-level `business_admin`/`super_admin`/`customer` string checks
- [x] `1.3` Tenant isolation (done 2026-09-14): optional `{businessId}` on `getProfessionalsByCategory`/`Specialty`, wired through guest-booking call sites (null-safe); `syncUserInAppointments` commits in 500-write chunks; `recordPayment` adopts `businessId` from linked appointment (best-effort); 12th composite index deployed; isolation tests extended (category + 4 payment cases). 301/301 tests, 0 analyze issues
- [x] `1.4` Provider contracts (done 2026-09-14): `isLoading`/`error` + begin/end on payment + notification providers (failures surface instead of vanishing into logs); `copyWith` replaces direct list mutation (payment status, notification read flags); `_endLoading` now clears stale `errorMessage` (was shown forever in booking UI); admins load business scope in `_reloadAppointments`; deterministic most-frequent `revenueCurrency`; `getAppointmentById` logs instead of silent null; auth exemption documented (return-value contract). New `notification_provider_test.dart` (6) + 7 payment + 3 appointment tests. 317/317 tests, 0 analyze issues
- [x] `1.5` Booking correctness (done 2026-09-14): `isRangeAvailable` collisions use instant-based `intervalsOverlap` (wall-clock kept only for hours/breaks) + Budapest DST fall-back regression test + range/slot agreement test; `createAppointmentAtomic` returns id, zero param mutation (interface `Future<String>`, provider uses returned id for notifications); `insertAppointment` deprecated (no lib callers); `projectId`/DEBUG log leaks removed. Server-side validation stub DEFERRED to Blaze money-decision (no Functions on Spark). 320/320 tests, 0 analyze issues
- [x] `1.6` Payments (done 2026-09-14): `Payment` fully immutable (`final` fields); `depositAmount`/`noShowFee` added with safe legacy defaults + `balanceDue` getter; `recordPayment` returns id, zero mutation end-to-end (repo→provider→page, which previously relied on `payment.id` side-effect); deposit input with validation on record form; receipt shows deposit/balance/no-show rows; refund path covered by existing `refunded` status. New `payment_test.dart` (7) + returned-id test. 328/328 tests, 0 analyze issues
- [x] `1.7` Notifications (done 2026-09-14): deterministic FNV-1a reminder ids (replaces unstable, possibly-negative `hashCode` — cancels now survive restarts); web outbox + drain surfaces reminders in-app via provider (session-persistent, never Firestore-spam; matters: pilot runs on web); cancel/cancelAll symmetric; shared cancel dialog (was duplicated verbatim); `debugPrint` removed; generic errors no longer mislabeled 'Booking declined'. New helper (7) + merge (1) + dialog widget (2) tests. 338/338 tests, 0 analyze issues
- [x] `1.8` Analytics (done 2026-09-14, Phase 1 COMPLETE): revenue counts each booking once (completed payment wins over price; orphans still count; pending ignored); `businessId` scoping defensive-filter + dashboard passes it; utilization capacity derived from each member's schedule (defaults still yield 40, old pinned values preserved); weekly-vs-monthly window mismatch documented for Phase 6. Deliberately changed the 180.0 test to 130.0 (old value WAS the bug). +5 tests. 343/343 tests, 0 analyze issues

**Exit:** every drawer/dashboard action works for all 4 roles on Android/Web/Windows; zero silent failures.

## Phase 1.9 — Code-review hardening (3-reviewer audit 2026-09-14)

- [x] `1.9` Review fixes (done 2026-09-14): booking create/reschedule stamp `businessId` (was defeating all tenant scoping on the hottest write); rules `business_admin` update constrained to non-role fields (was privilege escalation); availability query rebuilt without `whereNotIn` (range+not-in on different fields is rejected by Firestore — every slot read as taken); tenant scope threaded through day-availability reads + confirm guard + reschedule check; earnings loads scoped; `getProfessionalsByBusiness` rethrows instead of `[]`; admin realtime subscription; web-reminder markAll/reschedule correctness; receipt id clamp; add-payment null-id guard; id-less reminder skip; revenue counts collected cash (deposit-aware); +4 availability/payment indexes deployed (17 total). Deliberately kept (documented in code): login-branch wizard default, bookable admins, weekly-vs-monthly utilization. +8 tests. 351/351 tests, 0 analyze issues, rules+indexes deployed

## Phase 2 — Competitive parity (after Phase 1, in this order)

- [x] `2.0` Batch A — dead-code deletion (done 2026-09-14): removed `insertAppointment`, `watchProfessionals`, singular `watchAppointment`, `getProfessionalsBySpecialty`, `isProfessional`, unused counters, `addNotification`, `_buildNotificationMessage`, `api_access` (+ all fake overrides; appointment seeding via explicit `seedAppointment` helper). Kept `getPaymentByAppointment` (pins payment tenant isolation). Also reverted `dart format` fallout on 2 untouched files; braced 15 pre-existing `curly_braces` infos to keep CI exit 0. 356/356 tests, 0 analyze issues
- [x] `2.0` Batch B — picker labels + success loop (done 2026-09-14): `selectStaffMember`/`anyAvailable`/`bookAnother` keys in all 4 locales (regenerated); "Any available" auto-assigns first pro instead of erroring at confirm; success shows price + "Book another" → services. New `booking_page_test` (2) + `success_page_test` (3). 361/361 tests, 0 analyze issues
- [x] `2.0` Batch C — slots + Confirm + empties (done 2026-09-14): slot dropdown pre-filtered by availability/hours/breaks (end-overflow also gone); "fully booked" state; Confirm names its blocker; genuine-empty gains "Browse other categories"; services stream errors show message + Retry; 6 l10n keys added (EN/DE/HU/RO, regenerated). New booking widget tests (4). 365/365 tests, 0 analyze issues
- [x] `2.0` Batch D — consistency sweep (done 2026-09-14): `completeProfile` copy explains the sign-in detour (login owns completion dialog — verified, not a loop); wizard no-business blank → guidance + login CTA (self-creation needs product+rules call, noted); all error snackbars via `ErrorHandler` (success stays plain); dates/currency/amounts routed through `FormatHelper` (earnings+receipt); admin landing gains Team/Services/Calendar/Analytics grid; 48dp swatches + Semantics; status colors unified via `StatusColorHelper` (kills 2nd duplicate + hardcoded reds/grey); `collectedFor` shared by aggregate/provider/CSV (+5 tests). Deferred with rationale: full AnalyticsPage→service rewire + charts theming (Phase 6). 370/370 tests, 0 analyze issues. Phase 2.0 COMPLETE
- [x] `2.1` Cancellation policy + deposits + no-show (done 2026-09-14): `BusinessSettings` gains deposit/no-show fields with clamped getters; policy editor in Business Settings (window/deposit/fee, validated); provider + dialog enforce the business window (dynamic messages, 2h fallback); staff "Mark as no-show" (past-only) auto-records pending fee; booking deposit notice + payment-form prefill (collection stays offline — Phase 4). +16 tests. 386/386 tests, 0 analyze issues
- [ ] `2.2` Reminders: email now; SMS via pass-through credits; 1h + 24h toggles; quiet hours
- [ ] `2.3` Waitlist / auto-fill on cancel
- [ ] `2.4` Packages, memberships, gift cards, tips, staff commission tracking
- [ ] `2.5` Reviews + ratings post-completion
- [ ] `2.6` Calendar sync (Google/Outlook/iCloud two-way); fix web export no-op
- [ ] `2.7` CRM self-serve CSV export for owners (anti-Booksy differentiator)
- [ ] `2.8` Discovery: Google Reserve + Instagram/Facebook Book Now link generator (no marketplace commission ever)
- [ ] `2.9` Multi-location: location-scoped services/staff, admin + customer pickers (PLAT-0801–0804)

## Phase 3 — Any-domain white-label

- [ ] `3.1` Finish `specialty→category` rename with dual-read migration; `BusinessType` drives catalog/fields/wizard steps
- [ ] `3.2` Full branding: wire `secondaryColor/logo/businessName/favicon/typography`; `TenantBrandHeader` uses `effective*`; footer white-label toggle by plan; purge platform leaks from tenant surfaces (receipt header/thanks, earnings share text, calendar event titles/PRODID/`@restorahub.app` UIDs, fallback brand, `appTitle`); replace pilot-teal defaults with neutral seed
- [ ] `3.3` Custom domains + slugs; second-tenant onboarding with zero code changes (PLAT-1005)
- [ ] `3.4` Harden 9-step setup wizard (batch writes, resume, back-jump rules)
- [ ] `3.5` i18n completion: all admin/wizard strings into `.arb`, locale parity gate in CI; move model display strings (`methodLabel`/`statusLabel`/`displayLabel`/validation) behind l10n-aware formatters

## Phase 4 — Fair monetization

- [ ] `4.1` Enforce `FeatureGate` in UI + rules for `analytics/multi_location/custom_branding/api_access/online_booking/staff_management` (PLAT-0603–0607); consult `PlanDefinitions`, not just `business.hasFeature`
- [ ] `4.2` Stripe billing: status sync (0701), upgrade/downgrade (0702), trial expiry (0703), payment↔subscription link (0704); webhooks via Cloud Functions, never trust client
- [ ] `4.3` Plans: Trial (14d full Pro) → Basic (1 location) → Pro (deposits, marketing, API) → Enterprise (multi-location, SSO/HIPAA, SLA); grandfather pilot
- [ ] `4.4` Publish limits table + data-export promise in-app

## Phase 5 — Scale hardening

- [ ] Pagination on all lists (PLAT-1001); denormalization removal (1002); Cloud Functions validation (1003); ownership verification on direct-ID reads/writes ( booking/user/service/payment by-id paths trust caller `businessId`); scope `syncUserInAppointments` + `isEmailTaken` per tenant; tighten `appointments allow list` alongside backfill
- [ ] App Check + Crashlytics + performance tracing; offline cache + conflict policy
- [ ] iOS/macOS/Linux: add Firebase options or officially drop (today they crash at init)

## Phase 6 — Moat (after revenue)

- [ ] Advanced analytics: retention, service popularity, staff leaderboard, peak heatmap (0901–0904)
- [ ] AI no-show prediction + smart reminders; public API + Zapier/n8n; branded client app toggle

---

## Execution rules

* One sub-phase per branch/PR: migration-safety note, rules+index diff, fake tests, per-role smoke script.
* Additive only: `fromMap` defaults, no renames without dual-read + backfill.
* Every Firestore query ships with its index in the same PR.
* Pilot gate: RESTORE by MAYA login → book → remind → pay → receipt → export passes before merge.
* FREE-first (standing): Google free tier only. No paid service/tier without owner approval proving
  no free alternative or clear worth. Applies to every phase, including billing/SMS infra choices.
* Done = code + tests + `analyze`/`test` green + loading/empty/error states + tenant + rules review (AGENTS.md).

## 8. Archive log

On 2026-09-13 the following stale trackers were moved to `docs/archive/` and superseded by this file:
`CHECKPOINT.md` (149/149, 2026-08-25), `software_development_path.md` (KILO draft v1.0, baseline 108 tests),
`docs/index.md`, `docs/technical_debt.md` (TD-001–TD-016), `docs/models_audit.md`, `docs/providers_audit.md`,
`docs/repositories_audit.md`, `docs/navigation_audit.md`, `docs/firestore_audit.md`,
`docs/firestore_security_audit.md`, `docs/firestore_query_inventory.md`, `docs/architecture_overview.md`,
`docs/refactor_candidates.md`, `docs/testing_audit.md`. `README.md` slimmed to getting-started.
Root `*_AUDIT.md` files remain as historical references.
