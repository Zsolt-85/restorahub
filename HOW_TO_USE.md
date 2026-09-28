# HOW TO USE — RestoraHub (Restore by Maya pilot)

Live app: https://restorahub-2da2c.web.app — full manual: [`docs/user-manual.md`](docs/user-manual.md).

## Customer (phone or browser)

1. Open the app → **Login** (or Register as Customer, set name + phone).
2. **Home tab** — greeting, next visit hero, upcoming + history.
3. **Book tab** — 4 steps: pick a service (photos, prices) → pick your
   professional → pick date + time (crossed-out = taken) → confirm.
   Haptic + summary screen means it worked. **Add to calendar** keeps a copy.
4. **Visits tab** — reschedule or cancel (within the 2h cutoff), view history.
5. **Profile tab** — edit details, language, theme (light/dark/rose/indigo),
   logout. Dark mode is fully supported.

If something fails to load you get a plain-English message — retry once,
then screenshot it for support.

## Owner / staff (Maya)

- First login may ask to complete profile (specialty, hours).
- Customers book you from the Book tab; requests needing approval show on
  your dashboard → **Accept / Decline**.
- Walk-ins: professional manual booking from your dashboard.
- Record payments on completed visits; receipts generate automatically.
- One-time setup (business creation, linking, policy): see manual §0–§2.

## Re-tweak the brand (no code, ~2 minutes)

1. Open `assets/brand/maya.json` — every key is documented in the manual §6.
2. Change color (`seedColor`), fonts, name, tagline, or photo URLs.
3. Hot restart (`R` in `flutter run`) or rebuild the web app.
4. Check login header, Home, one wizard step, success screen.
5. The file is git-tracked — it IS the backup. Copy it per future tenant.

## Troubleshooting (first aid)

| Symptom | Fix |
|---|---|
| Stuck on spinner | Check connection, retry; re-login refreshes data |
| No professionals listed | Staffer must log in once (publishes profile) |
| Initials instead of photos | Stock catalog covers services; staff photos pending upload |
| Wrong theme/colors | Settings → theme; brand colors come from `maya.json`/Business Settings |
