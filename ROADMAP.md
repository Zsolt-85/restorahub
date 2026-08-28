# RestoraHub — Development Roadmap

## Current Status

- **Sprints 1-6 Complete**: 228/228 tests passing, 0 analysis errors
- **Production deployment**: https://restorahub-2da2c.web.app
- **Pilot tenant**: RESTORE by MAYA

## Sprint History

| Sprint | Focus | Status | Tests |
|--------|-------|--------|-------|
| 1 | Foundation — Baseline, Domain audit, Security audit, Firestore rules | ✅ | 123/123 |
| 2 | Model & Security — Business expansion, Repository scoping, Pagination | ✅ | 149/149 |
| 3 | Domain Generalization — Rename professional→staff, Service decoupling | ✅ | 155/155 |
| 4 | Business Lifecycle — State machine, BusinessType selection | ✅ | 179/179 |
| 5 | Onboarding & White-Label — Setup wizard, Branding, Tenant themes | ✅ | 210/210 |
| 6 | Feature Entitlements — FeatureGate service, Plan definitions | ✅ | 228/228 |

## Active Sprint

### Sprint 7 — Pilot Hardening
**Goal**: Prepare the platform for production pilot with RESTORE by MAYA.

| Task | Description | Status |
|------|-------------|--------|
| PLAT-0003 | ARCHITECTURE.md documentation | ✅ Complete |
| PLAT-0004 | AGENTS.md finalization | ✅ Complete |
| PLAT-0005 | ROADMAP.md creation | ✅ Complete |
| E2E-001 | End-to-end test documentation | ✅ Complete |

### Sprint 8 — UI Feature Gating
**Goal**: Consume `FeatureGate` in the UI to hide/disable features by plan.

| Task | Description | Status |
|------|-------------|--------|
| PLAT-0603 | Route guards for feature-gated pages | ⏳ Pending |
| PLAT-0604 | Analytics gated behind `analytics` feature | ⏳ Pending |
| PLAT-0605 | Multi-location gated behind `multi_location` feature | ⏳ Pending |
| PLAT-0606 | Custom branding gated behind `custom_branding` feature | ⏳ Pending |
| PLAT-0607 | API access gated behind `api_access` feature | ⏳ Pending |

### Sprint 9 — Subscription & Billing
**Goal**: Implement billing infrastructure.

| Task | Description | Status |
|------|-------------|--------|
| PLAT-0701 | Subscription status sync with Firestore | ⏳ Pending |
| PLAT-0702 | Plan upgrade/downgrade flow | ⏳ Pending |
| PLAT-0703 | Trial expiration handling | ⏳ Pending |
| PLAT-0704 | Payment recording linked to subscription | ⏳ Pending |

### Sprint 10 — Multi-Location
**Goal**: Enable businesses to manage multiple locations.

| Task | Description | Status |
|------|-------------|--------|
| PLAT-0801 | Location model and Firestore collection | ⏳ Pending |
| PLAT-0802 | Location-scoped services and staff | ⏳ Pending |
| PLAT-0803 | Location selector in admin UI | ⏳ Pending |
| PLAT-0804 | Customer location selection during booking | ⏳ Pending |

### Sprint 11 — Advanced Analytics
**Goal**: Expand analytics with business insights.

| Task | Description | Status |
|------|-------------|--------|
| PLAT-0901 | Customer retention metrics | ⏳ Pending |
| PLAT-0902 | Service popularity ranking | ⏳ Pending |
| PLAT-0903 | Staff performance comparison | ⏳ Pending |
| PLAT-0904 | Peak hours heatmap | ⏳ Pending |

### Sprint 12 — Platform Scale
**Goal**: Prepare for multi-tenant scale.

| Task | Description | Status |
|------|-------------|--------|
| PLAT-1001 | Pagination for all list endpoints | ⏳ Pending |
| PLAT-1002 | Denormalized data removal from Appointment/Payment | ⏳ Pending |
| PLAT-1003 | Cloud Functions for server-side validation | ⏳ Pending |
| PLAT-1004 | Custom domain resolution | ⏳ Pending |
| PLAT-1005 | Second tenant onboarding without code changes | ⏳ Pending |

## Milestones

| Milestone | Target | Status |
|-----------|--------|--------|
| Platform Ready (Sprint 6) | Core multi-tenant SaaS functional | ✅ Complete |
| Pilot Ready (Sprint 7) | RESTORE by MAYA can operate | ✅ Complete |
| Feature Complete (Sprint 8-10) | All planned features shipped | ⏳ In Progress |
| Scale Ready (Sprint 11-12) | Multi-tenant scale validated | ⏳ Pending |

## Key Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Test coverage | 90%+ | 228 tests |
| Static analysis errors | 0 | 0 |
| Sprint velocity | 2 weeks | 2 weeks |
| Pilot tenants | 1+ | 1 (RESTORE by MAYA) |
