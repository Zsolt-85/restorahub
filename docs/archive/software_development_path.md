# Software Development Path

Current time: 2026-08-25T18:39:12+03:00
Working directory: C:\\restorahub
Workspace root folder: C:\\restorahub
Active file: CHECKPOINT.md
Visible files:

* CHECKPOINT.md
Open tabs:
* CHECKPOINT.md
* lib/pages/professional\_manual\_booking\_page.dart
* lib/pages/booking\_page.dart
* lib/widgets/professional\_calendar\_view.dart



RESTORAHUB → WHITE-LABEL SAAS PLATFORM

Master Product, Architecture \& Execution Roadmap



Document status: Draft v1.0

Purpose: Master roadmap for product transformation

Primary development environment: Flutter / Dart / Firebase / VS Code / KILO agentic coding

Current baseline: Multi-tenant foundation implemented; 108/108 tests passing; flutter analyze clean

Pilot tenant: RESTORE by MAYA

Long-term objective: Configurable white-label SaaS platform for appointment/service-based businesses

1\. Product Vision

1.1 Vision



Build a platform that allows a business to launch its own branded digital operating environment without requiring custom software development.



The platform should support businesses whose core workflow involves:



&#x20;   customers

&#x20;   services

&#x20;   staff/professionals

&#x20;   availability

&#x20;   appointments

&#x20;   notifications

&#x20;   payments

&#x20;   customer management

&#x20;   business administration



The platform should be capable of expanding into different verticals without contaminating the universal core with industry-specific assumptions.

2\. What We Are Actually Building



The product is not:



&#x20;   "An appointment booking application."



The product is:



&#x20;   A configurable operating platform for service businesses.



The booking system is the first major capability.



Eventually the platform should be capable of supporting:



Business

│

├── Customers

├── Staff

├── Services

├── Locations

├── Scheduling

├── Appointments

├── Notifications

├── Payments

├── Calendar

├── Analytics

├── CRM

├── Marketing

├── Memberships

├── Packages

├── Integrations

└── Vertical Modules



3\. Product Principles



These principles should guide every future architectural decision.

P1 — Multi-tenancy first



No business must ever be able to access another business's data.



Tenant isolation is a security requirement, not merely a filtering feature.

P2 — Configuration over customization



When two businesses differ only in configuration:



configure the platform.



Do not fork the code.

P3 — Modules over core pollution



If a feature is specific to an industry:



build it as a module.



Do not add:



if (businessType == 'automotive')



throughout the core.

P4 — White-label by design



The customer should experience:



&#x20;   RESTORE by MAYA



rather than:



&#x20;   RestoraHub.



The platform should be invisible or optionally visible.

P5 — Zero-code tenant creation



Eventually:



&#x20;   Creating a new customer business must not require a developer.



P6 — Security before convenience



Every feature must consider:



&#x20;   authentication

&#x20;   authorization

&#x20;   tenant isolation

&#x20;   Firestore rules

&#x20;   role boundaries

&#x20;   data exposure

&#x20;   auditability



P7 — Automation over feature accumulation



Prioritize features that remove repetitive business work.

P8 — Real customers define priorities



RESTORE by MAYA is the first real-world validation environment.



Actual usage beats assumptions.

4\. Current State



The existing system already contains substantial functionality.

Authentication



&#x20;   Firebase Auth

&#x20;   Registration

&#x20;   Login

&#x20;   Password reset

&#x20;   Profile completion

&#x20;   Role assignment



Roles



&#x20;   customer

&#x20;   professional

&#x20;   business\_admin

&#x20;   super\_admin



Booking



&#x20;   service selection

&#x20;   professional selection

&#x20;   availability

&#x20;   slot generation

&#x20;   atomic creation

&#x20;   confirmation

&#x20;   cancellation

&#x20;   rescheduling

&#x20;   state machine



Professional management



&#x20;   schedule

&#x20;   working hours

&#x20;   slot duration

&#x20;   buffer/break configuration

&#x20;   incoming bookings

&#x20;   manual booking



Notifications



&#x20;   real-time Firestore streams

&#x20;   unread badge

&#x20;   booking request

&#x20;   confirmation

&#x20;   cancellation

&#x20;   rescheduling



Calendar



&#x20;   native calendar

&#x20;   Google Calendar / iCal/web export

&#x20;   reminders



Analytics



&#x20;   revenue

&#x20;   appointment statistics

&#x20;   charts

&#x20;   CSV export

&#x20;   operational KPIs



Localization



&#x20;   EN

&#x20;   RO

&#x20;   DE

&#x20;   HU



Themes



&#x20;   multiple high-contrast themes

&#x20;   tenant branding foundation



Multi-tenancy



Already implemented:



&#x20;   businessId

&#x20;   BusinessProvider

&#x20;   scoped repositories

&#x20;   tenant-scoped notifications

&#x20;   tenant-scoped analytics

&#x20;   tenant-scoped payments

&#x20;   business settings

&#x20;   team management

&#x20;   admin calendar

&#x20;   super-admin dashboard

&#x20;   tenant CRUD

&#x20;   tenant isolation tests



Quality



Current reported baseline:



flutter test       108/108

flutter analyze    0 errors



This is our starting point.

5\. Critical Transformation



The current application was originally designed around:



&#x20;   wellness / beauty appointments.



The next phase is to identify everything that is accidentally domain-specific.



Every existing component should be classified as one of four categories.

6\. Domain Classification

6.1 CORE



Universal functionality.



Examples:



Business

User

Customer

Staff

Service

Appointment

Availability

Location

Notification

Payment

Calendar



6.2 CONFIGURATION



Behavior controlled by the tenant.



Examples:



Business type

Branding

Terminology

Currency

Language

Booking rules

Cancellation rules

Opening hours

Services

Staff

Locations

Notifications



6.3 VERTICAL MODULE



Industry-specific functionality.



Examples:



Vehicle

Medical information

Equipment

Treatment packages

Memberships

Inventory

Insurance

Patient records

Vehicle history



6.4 CUSTOMER-SPECIFIC



Something needed by one customer but not justified as a platform capability.



These should not automatically enter the core.

7\. PHASE 0 — Baseline \& Engineering Control

Objective



Create a stable foundation before further transformation.

Tasks

PLAT-0001 — Create stable baseline



&#x20;   Verify tests

&#x20;   Verify analysis

&#x20;   Verify production deployment

&#x20;   Tag current Git state

&#x20;   Document current version



PLAT-0002 — Establish environments



Define:



development

staging

production



Ensure production data cannot accidentally be destroyed during development.

PLAT-0003 — Document architecture



Create:



ARCHITECTURE.md



Document:



&#x20;   providers

&#x20;   repositories

&#x20;   models

&#x20;   Firebase

&#x20;   routing

&#x20;   multi-tenancy

&#x20;   authentication

&#x20;   roles

&#x20;   notifications

&#x20;   booking lifecycle



PLAT-0004 — Establish agent rules



Create:



AGENTS.md



This becomes the primary instruction set for KILO.

PLAT-0005 — Create roadmap



Create:



ROADMAP.md



8\. PHASE 1 — Domain/Core Audit

Objective



Discover hidden wellness-specific assumptions.



This should initially be read-only analysis.



Do not ask KILO to modify the application yet.

PLAT-0101



Audit:



lib/models

lib/repositories

lib/providers

lib/helpers

lib/pages

lib/widgets

lib/constants

test



Search for:



massage

beauty

hair

facial

spa

specialty

profession

treatment



and other domain assumptions.

PLAT-0102 — Classification report



Produce:



DOMAIN\_AUDIT.md



For every relevant item:



File

Component

Current assumption

Classification

Recommended action

Risk



Example:



Appointment.specialty

→ configuration / legacy

→ remove if redundant



PLAT-0103 — Define canonical domain model



Document the target model.

9\. Target Domain Model



Conceptually:



Platform

│

├── Business

│   ├── Branding

│   ├── Settings

│   ├── Subscription

│   ├── Features

│   └── Locations

│

├── Users

│   ├── Customer

│   ├── Staff

│   ├── Business Admin

│   └── Super Admin

│

├── Catalog

│   └── Services

│

├── Scheduling

│   ├── Availability

│   ├── Working Hours

│   ├── Breaks

│   └── Resources

│

├── Appointments

│

├── Notifications

│

├── Payments

│

└── Analytics



10\. PHASE 2 — Business Lifecycle

Objective



Make Business a first-class SaaS object.



Business should eventually contain concepts equivalent to:



id

name

slug

businessType

status

ownerId

contactInformation

branding

settings

subscription

featureEntitlements

createdAt

updatedAt



Business status



Define:



trial

active

suspended

cancelled

archived



with documented behavior.

PLAT-0201 — Business lifecycle state machine



Define allowed transitions.



Example:



trial → active

trial → cancelled

active → suspended

suspended → active

active → cancelled

cancelled → archived



No implementation should happen until the rules are defined.

11\. PHASE 3 — Business Types



Introduce:



businessType



Initially:



wellness

custom



Do not implement five industries yet.



The objective is to prove that the platform can distinguish configuration without duplicating the application.

12\. PHASE 4 — Zero-Code Tenant Onboarding



This is one of the most important milestones.

Target flow



Super Admin

&#x20;    ↓

Create Business

&#x20;    ↓

Assign Business Admin

&#x20;    ↓

Admin Login

&#x20;    ↓

Setup Wizard

&#x20;    ↓

Business Information

&#x20;    ↓

Branding

&#x20;    ↓

Business Type

&#x20;    ↓

Services

&#x20;    ↓

Staff

&#x20;    ↓

Schedule

&#x20;    ↓

Booking Rules

&#x20;    ↓

Launch



Setup wizard

Step 1



Business information.

Step 2



Brand.

Step 3



Business type.

Step 4



Services.

Step 5



Staff.

Step 6



Opening hours.

Step 7



Booking configuration.

Step 8



Preview.

Step 9



Launch.

13\. PHASE 5 — White-Label Engine



Existing branding capabilities should be consolidated into a proper tenant branding model.



Potential configuration:



BusinessBranding

├── businessName

├── logo

├── favicon

├── primaryColor

├── secondaryColor

├── accentColor

├── typography

├── customerFacingName

└── customDomain



Eventually:



customer-domain.com

&#x20;       ↓

Tenant Resolver

&#x20;       ↓

Business

&#x20;       ↓

Branding

&#x20;       ↓

Application



14\. PHASE 6 — Feature Entitlement System



This is the foundation of monetization.



Introduce concepts such as:



Plan

Feature

BusinessSubscription

FeatureEntitlement



Potential features:



onlineBooking

calendarIntegration

notifications

analytics

advancedAnalytics

customBranding

multipleStaff

multipleLocations

payments

marketing

membership

api

integrations



15\. Initial Plans



Don't overcomplicate pricing.



Start conceptually with:



Founder

Starter

Business

Pro

Enterprise



The Founder plan is for your pilot.

16\. Feature Evaluation



Features should be checked through an entitlement service rather than scattered role logic.



Concept:



FeatureGate.canAccess(

&#x20;   businessId,

&#x20;   Feature.analytics

)



This gives us future flexibility.

17\. PHASE 7 — RESTORE BY MAYA PILOT



This is where the software becomes a product.



Treat:



&#x20;   RESTORE by MAYA



as Customer #0.



Not a test account.



A real business.

18\. Pilot Metrics



Track:

Usage



&#x20;   bookings/week

&#x20;   active customers

&#x20;   returning customers

&#x20;   staff usage

&#x20;   admin usage



Reliability



&#x20;   failed bookings

&#x20;   failed notifications

&#x20;   synchronization issues

&#x20;   calendar failures



Business outcomes



&#x20;   time saved

&#x20;   reduced manual communication

&#x20;   reduced no-shows

&#x20;   reduced scheduling conflicts



UX



&#x20;   confusing screens

&#x20;   unnecessary steps

&#x20;   repeated manual tasks



19\. Feedback Classification



Every request from the pilot goes into one of:

CORE



Universal.

CONFIGURATION



Tenant setting.

MODULE



Industry-specific.

CUSTOM



Specific to one business.



This classification must become a habit.

20\. PHASE 8 — Customer #1



Find one external business.



Ideal first targets:



&#x20;   massage

&#x20;   beauty

&#x20;   barber

&#x20;   physiotherapy

&#x20;   fitness

&#x20;   small wellness business



Don't target hospitals first.



Don't target large enterprises first.



We want low complexity and high learning speed.

21\. Customer #1 Validation



The goal isn't:



&#x20;   "They like the application."



The goal is:



&#x20;   They use it and pay for it.



Even:



€10–€30/month



is more meaningful than ten people saying they like the concept.

22\. PHASE 9 — Monetization



After real usage is proven, introduce subscription billing.



Possible model:

Starter



Basic booking.

Business



Branding + analytics + advanced management.

Pro



Automation + advanced features.

Enterprise



Custom integrations, API, multiple locations, custom deployment.



Exact prices should be determined from market research and customer interviews rather than invented now.

23\. PHASE 10 — Vertical Expansion



Only after the core has been validated.

Vertical 1



Wellness.



Already underway.

Vertical 2



Beauty.



Minimal adaptation.

Vertical 3



Fitness.



Test resources/memberships/packages.

Vertical 4



Automotive.



Test asset/resource concepts:



Customer

Vehicle

Service

Technician

Appointment



Vertical 5



Healthcare scheduling.



Start only with scheduling.



Do not immediately introduce medical records or sensitive clinical workflows.

24\. Long-Term Architecture



Eventually:



&#x20;                 PLATFORM CORE

&#x20;                      │

&#x20;      ┌───────────────┼───────────────┐

&#x20;      │               │               │

&#x20;  Scheduling       Customers       Payments

&#x20;      │               │               │

&#x20;      └───────────────┼───────────────┘

&#x20;                      │

&#x20;                 MODULE SYSTEM

&#x20;                      │

&#x20;       ┌──────────────┼──────────────┐

&#x20;       │              │              │

&#x20;    Wellness       Automotive    Healthcare

&#x20;       │              │              │

&#x20;    Packages        Vehicles      Scheduling

&#x20;    Membership      Maintenance   Patient workflow



25\. Security Roadmap



Security should be treated as a permanent workstream.

SEC-001



Review every Firestore collection.



For each:



Who can read?

Who can write?

Which tenant?

Which role?

Which ownership condition?



SEC-002



Attempt cross-tenant access deliberately.



Tests should prove:



Tenant A cannot read Tenant B

Tenant A cannot write Tenant B

Tenant A cannot infer Tenant B data



SEC-003



Test privilege escalation.



Examples:



customer → professional

professional → business\_admin

business\_admin → super\_admin



must not be possible through client-side manipulation.

SEC-004



Review Cloud Functions/server-side logic if introduced.

26\. Testing Strategy



Testing becomes part of the architecture.

Unit tests



Models, helpers, providers.

Repository tests



Tenant filtering, error handling.

Security tests



Cross-tenant isolation.

Integration tests



Important user workflows.

Smoke tests



Real Firebase environment.

Regression tests



Every significant bug gets a regression test.

27\. Definition of Done



A task isn't complete simply because it compiles.



For significant features:



&#x20;   implementation complete

&#x20;   tests added

&#x20;   existing tests pass

&#x20;   localization added

&#x20;   loading state

&#x20;   empty state

&#x20;   error state

&#x20;   responsive layout

&#x20;   accessibility/contrast checked

&#x20;   tenant isolation reviewed

&#x20;   authorization reviewed

&#x20;   Firestore rules reviewed

&#x20;   logging reviewed

&#x20;   documentation updated

&#x20;   flutter analyze

&#x20;   flutter test



28\. KILO / Agentic Development Rules



This is extremely important.



Create AGENTS.md.



KILO should follow these rules:

Rule 1



Do not modify unrelated code.

Rule 2



Do not refactor architecture without an explicit task.

Rule 3



Do not remove tests merely to make them pass.

Rule 4



Do not weaken Firestore rules.

Rule 5



Do not bypass tenant filtering.

Rule 6



Do not introduce hard-coded tenant IDs.

Rule 7



Do not introduce hard-coded vertical logic into the core without approval.

Rule 8



Every bug fix should include a regression test where practical.

Rule 9



Do not expose raw exceptions to users.

Rule 10



Don't replace an existing abstraction with a new one without explaining why.

Rule 11



Before modifying a repository/provider/model, inspect its tests and consumers.

Rule 12



After implementation:



flutter analyze

flutter test



must be run.

29\. KILO Task Protocol



Every task should look like:



TASK ID:

PLAT-XXXX



TITLE:



OBJECTIVE:



CURRENT BEHAVIOR:



DESIRED BEHAVIOR:



SCOPE:



OUT OF SCOPE:



FILES LIKELY AFFECTED:



SECURITY CONSIDERATIONS:



TENANT CONSIDERATIONS:



TEST REQUIREMENTS:



ACCEPTANCE CRITERIA:



REGRESSION RISKS:



KILO should report:



Files changed

Why they changed

Tests added

Tests executed

Analysis result

Potential risks

Remaining TODOs



30\. Git Strategy



Use small commits.



Prefer:



PLAT-0101 audit domain assumptions

PLAT-0102 classify domain model

PLAT-0103 define canonical model



rather than:



make platform generic



Huge agentic commits are difficult to review and dangerous to revert.

31\. Product Metrics



Once customers arrive, create a small SaaS dashboard around:

Acquisition



&#x20;   businesses registered

&#x20;   businesses activated



Activation



&#x20;   setup completed

&#x20;   first service created

&#x20;   first staff member created

&#x20;   first booking



Engagement



&#x20;   weekly active businesses

&#x20;   bookings/business

&#x20;   active staff



Retention



&#x20;   businesses active after 30 days

&#x20;   businesses active after 90 days



Revenue



&#x20;   MRR

&#x20;   ARR

&#x20;   churn

&#x20;   ARPU



Reliability



&#x20;   booking failures

&#x20;   notification failures

&#x20;   payment failures



32\. North-Star Metric



Initially, I'd use:



&#x20;   Number of active businesses successfully processing real customer appointments through the platform.



Not:



&#x20;   number of registered accounts

&#x20;   number of features

&#x20;   number of downloads



A business that actually operates through the system is what matters.

33\. Competitive Strategy



Do not compete by saying:



&#x20;   "We have appointment booking."



That market is crowded.



The positioning should eventually become closer to:



&#x20;   Launch your own branded business platform without building software yourself.



Your differentiators:



&#x20;   white-label

&#x20;   multi-tenant

&#x20;   configurable

&#x20;   vertical extensibility

&#x20;   branded customer experience

&#x20;   business administration

&#x20;   scheduling

&#x20;   automation

&#x20;   integrations

&#x20;   potentially AI later



34\. What Not to Build Yet



Explicitly put these in the backlog:



Marketplace

AI receptionist

Advanced CRM

Complex marketing automation

Inventory

Medical records

Large enterprise workflows

Third-party marketplace

Complex billing

Dozens of verticals



They aren't forbidden forever.



They're simply not current priorities.

35\. Naming Strategy



Keep:



&#x20;   RestoraHub



as the internal/project name temporarily.



Do not perform a risky rename yet.



Later:

Naming Sprint



Generate 30–50 candidates.



Then check:



&#x20;   exact trademark

&#x20;   similar trademark

&#x20;   EUIPO

&#x20;   WIPO

&#x20;   USPTO

&#x20;   OSIM

&#x20;   domains

&#x20;   GitHub

&#x20;   App Store

&#x20;   Google Play

&#x20;   company names

&#x20;   pronunciation

&#x20;   international meaning



Then select the final platform brand.



RESTORE by MAYA remains a tenant/customer brand.

36\. Target Product Architecture



The conceptual architecture should eventually be:



&#x20;                   ┌──────────────────────┐

&#x20;                   │     SUPER ADMIN      │

&#x20;                   └──────────┬───────────┘

&#x20;                              │

&#x20;                   ┌──────────▼───────────┐

&#x20;                   │       PLATFORM       │

&#x20;                   │                      │

&#x20;                   │ Multi-Tenancy        │

&#x20;                   │ Authentication       │

&#x20;                   │ Authorization        │

&#x20;                   │ Billing              │

&#x20;                   │ Feature Entitlements │

&#x20;                   │ Branding             │

&#x20;                   │ Configuration         │

&#x20;                   └──────────┬───────────┘

&#x20;                              │

&#x20;         ┌────────────────────┼────────────────────┐

&#x20;         │                    │                    │

&#x20;┌────────▼────────┐  ┌────────▼────────┐  ┌───────▼─────────┐

&#x20;│    BUSINESS A   │  │    BUSINESS B   │  │    BUSINESS C   │

&#x20;│                 │  │                 │  │                 │

&#x20;│ RESTORE by MAYA │  │ Beauty Studio   │  │ Auto Service    │

&#x20;│                 │  │                 │  │                 │

&#x20;│ Branding        │  │ Branding        │  │ Branding        │

&#x20;│ Services        │  │ Services        │  │ Services        │

&#x20;│ Staff           │  │ Staff           │  │ Staff           │

&#x20;│ Customers       │  │ Customers       │  │ Customers       │

&#x20;│ Appointments    │  │ Appointments    │  │ Appointments    │

&#x20;└─────────────────┘  └─────────────────┘  └─────────────────┘



37\. The First Major Milestone



I would define:

MILESTONE 1 — PLATFORM READY



We declare it achieved when:



&#x20;   Domain audit complete

&#x20;   Core/configuration/module boundaries documented

&#x20;   Business lifecycle defined

&#x20;   Business types implemented

&#x20;   Tenant onboarding implemented

&#x20;   White-label configuration consolidated

&#x20;   Feature entitlement architecture implemented

&#x20;   Security audit complete

&#x20;   Cross-tenant tests passing

&#x20;   RESTORE by MAYA running successfully

&#x20;   New test tenant created without code modification

&#x20;   Documentation complete



That is the first major target.

38\. The Second Major Milestone

MILESTONE 2 — PRODUCT VALIDATED



&#x20;   RESTORE by MAYA using platform in real life

&#x20;   Real customer appointments

&#x20;   Documented user feedback

&#x20;   Major usability problems addressed

&#x20;   Second unrelated business onboarded

&#x20;   Second business uses system without custom code

&#x20;   At least one business willing to pay



39\. The Third Major Milestone

MILESTONE 3 — COMMERCIAL SAAS



&#x20;   Final platform name

&#x20;   Trademark clearance

&#x20;   Domain

&#x20;   Pricing

&#x20;   Subscription billing

&#x20;   Feature entitlements enforced

&#x20;   Customer onboarding

&#x20;   Terms/privacy/legal foundations

&#x20;   Support process

&#x20;   Monitoring

&#x20;   Backup/recovery

&#x20;   Production release process



40\. The Fourth Major Milestone

MILESTONE 4 — MULTI-VERTICAL



Demonstrate:



Wellness

Beauty

Fitness

Automotive



using the same platform core.



The goal isn't feature parity.



The goal is proving:



&#x20;   The architecture survives different business models.



41\. The Ultimate Goal



The long-term success story should be:



&#x20;   A business owner can arrive at the platform, select their industry, configure their business, upload their branding, add services and staff, and launch their own professional customer-facing booking/operations environment in minutes.



Then:



&#x20;   The platform becomes the operating layer underneath their business.



That is much more defensible than another appointment scheduler.

42\. What We Do When You Get Home



I recommend not starting with a coding prompt.



First, we'll turn this roadmap into three actual repository documents:



ROADMAP.md

ARCHITECTURE.md

AGENTS.md



Then we'll inspect your actual current repository against the roadmap.



The sequence should be:



&#x20;                TODAY

&#x20;                  │

&#x20;                  ▼

&#x20;       ┌─────────────────────┐

&#x20;       │ Existing RestoraHub │

&#x20;       └──────────┬──────────┘

&#x20;                  │

&#x20;                  ▼

&#x20;         DOMAIN / CODE AUDIT

&#x20;                  │

&#x20;                  ▼

&#x20;       CORE / CONFIG / MODULE

&#x20;             CLASSIFICATION

&#x20;                  │

&#x20;                  ▼

&#x20;         ARCHITECTURE PLAN

&#x20;                  │

&#x20;                  ▼

&#x20;         KILO IMPLEMENTATION

&#x20;                  │

&#x20;                  ▼

&#x20;          TEST + SECURITY

&#x20;                  │

&#x20;                  ▼

&#x20;      RESTORE BY MAYA PILOT

&#x20;                  │

&#x20;                  ▼

&#x20;         SECOND BUSINESS

&#x20;                  │

&#x20;                  ▼

&#x20;         FIRST PAID CUSTOMER

&#x20;                  │

&#x20;                  ▼

&#x20;            SAAS LAUNCH

&#x20;                  │

&#x20;                  ▼

&#x20;         MULTI-VERTICAL

&#x20;                  │

&#x20;                  ▼

&#x20;             PLATFORM



And I would make one rule for the entire project:



&#x20;   We never optimize for how much code we can produce. We optimize for how much reusable business value we can create without damaging the platform.



That's the mindset I want us to maintain while working with KILO.



When you get home, the best first move is to give KILO a read-only architecture audit prompt, not an implementation prompt. It should inspect the repository and tell us exactly how far the current codebase is from this roadmap. Then we can compare what we think we have with what the code actually contains, and start PLAT-0001 onward with evidence rather than assumptions.



