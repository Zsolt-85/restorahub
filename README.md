# RestoraHub

Salon-first booking app (Flutter + Firebase). Pilot salon: **RESTORE by MAYA** — customers open straight into her branded universe: Home greeting + next-visit hero, photo service discovery, 4-step booking wizard, summary success screen.
Live: https://restorahub-2da2c.web.app

Multi-business tooling (super-admin, setup wizard, tenant switching) stays intact underneath for prio-2 expansion.

> **Planning lives in [`ROADMAP.md`](ROADMAP.md)** — the single source of truth for status, phases, and progress.
> Old trackers were archived to `docs/archive/` on 2026-09-13.

## Getting started

```bash
flutter pub get
flutter run -d windows   # or android, web, chrome
```

## Checks

```bash
flutter analyze   # expect 0 issues
flutter test      # expect 464 passed + 1 skipped (pre-existing skip)
```

## Brand tweaks (no code)

Edit `assets/brand/maya.json` (colors, fonts, name, tagline, photo URLs),
hot restart, verify. Full workflow: [`docs/user-manual.md`](docs/user-manual.md) §6.
Design specs: `docs/superpowers/specs/`.

## Docs

| File | Purpose |
|---|---|
| `ROADMAP.md` | Master plan + progress tracker |
| `AGENTS.md` | AI agent coding rules |
| `HOW_TO_USE.md` | Operator & customer quick guide |
| `ARCHITECTURE.md` | System architecture |
| `docs/user-manual.md` | Full user manual (screens, policy, troubleshooting) |
| `docs/user_registration_manual.md` | Registration flow manual |
| `docs/superpowers/specs/` | Approved design specs |
| `docs/superpowers/plans/` | Implementation plans |
| `docs/archive/` | Superseded audits, checkpoints, debt lists (history only) |
