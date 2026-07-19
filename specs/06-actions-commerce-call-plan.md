# Actions, Booking Calls, Package Checkout, And Ask Agent Plan

This is the living execution plan for the itinerary activity **Actions** feature set.
Keep this file updated after every implementation step so another agent can resume
without rediscovering context.

## Current Status

Status: Completed.

Last updated: 2026-07-03.

## Scope

Add an **Actions** button beside **Directions** on each itinerary activity card.
The Actions flow routes users to:

- **Call the Venue**
- **Book or Buy Packages**
- **Ask Agent Anything**

This work must keep Wanderlust local-first by default while allowing the Twilio
call service to run on Google Cloud because Twilio webhooks and media streams
need public HTTPS/WSS endpoints.

## Architecture Decision Notes

- Flutter remains the owner of local preferences and saved itineraries.
- Backend agent services receive explicit request context from Flutter through
  the anonymous device/user context header.
- Twilio call execution may be hosted on Google Cloud.
- Twilio call logs may be stored in a Google Cloud database as a narrow exception
  to local-only persistence.
- Provider checkout secrets must never be stored in Flutter. Stripe secret keys
  remain server-side and are used only when a verified result is backed by
  Wanderlust Stripe inventory, Stripe Connect, or a public Stripe Payment Link.
- Raw card data must never be stored locally. The app opens the verified
  provider checkout in an external browser and does not store saved card info or
  local payment history for this feature.
- Calls, bookings, payments, itinerary lifecycle changes, major itinerary
  rewrites, exports, and deletes require explicit user confirmation.

## Guardrails To Preserve

- [x] Only one itinerary may be ACTIVE at a time.
- [x] ACTIVE-only location, event ingestion, ambient workflows, suggestions, and
      dynamic behavior updates remain gated.
- [x] Recommendations include brief reasoning and confidence/source context when
      relevant.
- [x] Social sources remain discovery-only and never factual authority.
- [x] Agent output is validated with typed schemas before persistence or side
      effects.
- [x] Booking calls require explicit user confirmation after details are shown.
- [x] Payments require explicit user confirmation through Stripe-safe flows.
- [x] No raw card data, API keys, service-account JSON, callback numbers, or
      reservation PII are committed or logged unnecessarily.

## Phase 0: Specs And Product Alignment

Status: Completed.

Tasks:

- [x] Update `specs/03-product-workflows-and-guardrails.md` to replace the
      older stop-level `Talk to Agent` CTA wording with the new **Actions**
      pattern where appropriate.
- [x] Document the narrow cloud persistence exception for Twilio call logs.
- [x] Document that Stripe payment operations must stay behind backend APIs.
- [x] Document that raw card data is never stored locally.
- [x] Update `specs/agentic-architecture.puml` once implementation shape is
      confirmed during the implementation phases.

Verification:

- [x] Search specs for stale CTA wording after updates.
- [x] Confirm local-first constraints still apply outside Twilio call logs and
      external provider records.

## Phase 1: Modular Architecture Refactor

Status: Completed.

Backend target modules:

- [x] `actions` routing/orchestration.
- [x] `booking` venue-contact resolution, booking intake, Twilio/Gemini Live
      call flow, call status, and call logs.
- [x] `manual_call` contact lookup and user-call script generation.
- [x] `commerce` activity-scoped package search, product/package detail,
      provider checkout handoff, and optional Stripe-backed checkout handling.
- [x] `ask_anything` general activity-scoped chat and CTA recommendation.
- [x] Shared schemas, validators, guardrails, repositories, and telemetry helpers.

Frontend target modules:

- [x] `features/activity_actions`.
- [x] `features/call_venue`.
- [x] `features/stripe_purchase`.
- [x] `features/ask_agent_anything`.
- [x] `features/profile`.
- [x] Full-page chat flows for Call Venue and Ask Agent Anything. The itinerary
      drawer chat remains local to the itinerary detail screen because it has
      route-gap mutation state and booking offer UI specific to that drawer.

Verification:

- [x] Backend unit tests cover new orchestration boundaries.
- [x] Flutter widget tests cover new navigation boundaries.

## Phase 2: Itinerary Activity Actions Entry Point

Status: Completed.

Tasks:

- [x] Replace the activity card stop-specific **Talk to Agent** action with an
      **Actions** button beside **Directions**.
- [x] Add `ActivityActionsPage`.
- [x] Pass itinerary ID, day index/ID, activity index/ID, venue name, place ID,
      coordinates, route context, and contact hints where available.
- [x] Render three options: **Call the Venue**, **Book or Buy Packages**, and
      **Ask Agent Anything**.

Verification:

- [x] Widget test confirms activity cards show **Directions** and **Actions**.
- [x] Navigation tests confirm each option opens the correct page.

## Phase 3: Call The Venue

Status: Completed.

Whole-page interface:

- [x] Reuse or extract the existing agent chat UI into a full-page chat shell.
- [x] First agent message presents two choices:
      **Book a reservation using an AI agent** and **Call the venue manually**.

AI booking flow:

- [x] Resolve venue point of contact using Google Places first.
- [x] If no contact is found, ask the user to input the venue contact manually.
- [x] Ask requestor name.
- [x] Ask date/time.
- [x] Validate date/time is parseable and in the future; re-ask on failure.
- [x] Ask pax count.
- [x] Validate pax count.
- [x] Ask callback phone. Callback phone is required for agent-assisted
      booking calls.
- [x] Ask optional additional remarks.
- [x] Generate a booking summary and Gemini Live telephone script.
- [x] Let the user edit summary/script details before calling.
- [x] Require explicit user confirmation before starting the call.
- [x] Preserve existing Twilio/Gemini Live call behavior:
      press `1` to repeat, press `2` to confirm received/booked, hangup before
      confirmation becomes failed or unconfirmed.

Manual call flow:

- [x] Resolve venue point of contact using Google Places first.
- [x] If contact is found, show it and ask what the user wants to ask.
- [x] If no contact is found, accept an optional user-supplied venue phone;
      otherwise show `No venue contact available`.
- [x] Generate and show a concise script plus the venue phone for the user to
      call personally.
- [x] Never expose agent calling or a **Use chat instructions** button in the
      manual flow. Agent-assisted booking exposes only its explicit
      **Call using agent** confirmation action.

Verification:

- [x] Backend tests cover contact found, contact missing, manual contact,
      invalid contact, invalid date/time, past date/time, pax validation,
      optional remarks, editable summary, explicit call confirmation, and Twilio
      fallback.
- [x] Flutter tests cover the conversational step order and full-page chat UI.

## Phase 4: Google Cloud Call Logging

Status: Completed.

Tasks:

- [x] Select the cloud database implementation for Twilio call logs.
- [x] Add least-privilege backend repository for call status log writes.
- [x] Store only minimal call-log metadata:
      call ID, hashed anonymous device/session ID, itinerary/activity reference,
      status transitions, timestamps, provider error code/message when available.
- [x] Avoid storing raw callback numbers, raw reservation names, raw venue phone
      overrides, or full transcripts unless a future requirement explicitly
      adds them with consent and retention rules.
- [x] Update Cloud Run/IaC/deployment docs for the call-log database.

Verification:

- [x] Tests confirm logs are redacted.
- [x] Security audit confirms no unnecessary PII or secrets in logs.

## Phase 5: Book Or Buy Packages With Provider Checkout

Status: Completed.

Tasks:

- [x] Add `BookOrBuyPackagesPage` with search bar, proceed/search icon,
      product/package cards, and paginated **More** behavior.
- [x] Preload the top 5 AI-selected purchasable packages/products for the
      current activity or venue.
- [x] Reveal additional products 5 at a time.
- [x] Process search only after the user presses the proceed/search control.
- [x] Support natural-language and ambiguous product descriptions through a
      backend activity-scoped package-search agent.
- [x] Verify recommendations against official or authorized provider sources
      where possible.
- [x] Add product/package detail page backed by verified provider data.
- [x] Open the verified provider checkout URL in an external browser rather
      than collecting payment details inside the app.
- [x] Do not create arbitrary Stripe Checkout Sessions for third-party products
      unless the result is Wanderlust-owned inventory, a connected seller
      product, or another valid Stripe-backed provider flow.
- [x] Show a clear external-checkout handoff state. Success/cancel callback
      handling remains provider-dependent and can be added when a selected
      provider exposes return URLs.
- [x] Do not implement local card storage or local payment history for this
      provider-checkout flow.

Security constraints:

- [x] Do not store raw card data locally or in backend app storage.
- [x] Do not expose Stripe or provider checkout secrets to Flutter.
- [x] Do not let an agent create a Checkout Session or redirect to checkout
      without explicit user action.
- [x] Do not represent arbitrary third-party products as Wanderlust-sold Stripe
      products unless there is a valid seller, reseller, Connect, or payment-link
      relationship.
- [x] Treat the external provider as the payment record source of truth unless a
      later explicit requirement adds a separate local receipt view.

Verification:

- [x] Backend tests cover product recommendation, search, pagination, detail,
      provider checkout URL validation, optional Stripe Checkout Session
      creation, and payment guardrails.
- [x] Flutter tests cover search execution, pagination, product detail,
      explicit external checkout handoff, and cancel/success return UI where
      available.

## Phase 6: Profile Rename

Status: Completed.

Tasks:

- [x] Rename **Preferences** page/nav label to **Profile**.
- [x] Keep reset preferences behavior.
- [x] Ensure resetting preferences does not delete saved itineraries.
- [x] Do not add payment history or saved-card UI for the provider-checkout
      flow.

Verification:

- [x] Widget tests confirm the Profile label.
- [x] Regression test confirms reset preferences keeps saved itineraries.

## Phase 7: Ask Agent Anything

Status: Completed.

Tasks:

- [x] Add activity-scoped full-page informational chat.
- [x] Support itinerary/activity questions, explanations, recommendations, and
      general travel information.
- [x] Detect booking intent and offer a CTA to **Call the Venue**.
- [x] Detect purchase intent and offer a CTA to **Book or Buy Packages**.
- [x] Keep this flow informational unless the user explicitly routes into the
      relevant action page.

Verification:

- [x] Tests cover informational answers, booking CTA recommendation, purchase
      CTA recommendation, and refusal of direct call/payment actions.

## Phase 8: Active Itinerary Edge Cases

Status: Completed.

Tasks:

- [x] Inspect current handling for skipped activities, late arrivals, off-route
      behavior, closed/unavailable places, and transport duration changes.
- [x] Ensure the app can propose recovery when activities are not followed.
- [x] Require explicit user acceptance before applying recovery proposals.
- [x] Preserve unchanged itinerary days when only partial recovery is requested.
- [x] Confirm inactive/completed itineraries do not run active services.

Verification:

- [x] Backend tests cover ACTIVE-only gates and recovery proposal behavior.
- [x] Flutter tests cover recovery proposal accept/reject UI where present.

## Phase 9: Deployment

Status: Completed.

Tasks:

- [x] Keep local-first app data behavior.
- [x] Deploy the Twilio-call service path to Google Cloud Run or keep the current
      Cloud Run backend configured for Twilio callbacks.
- [x] Ensure public HTTPS and WSS URLs route to Twilio webhook/media endpoints.
- [x] Configure secrets through Secret Manager for cloud-hosted call service.
- [x] Add cloud call-log database configuration.
- [x] Document exact redeploy commands after implementation.

Verification:

- [ ] Cloud Run health check passes. Requires deployed Cloud Run URL.
- [ ] Twilio webhook endpoint responds. Requires deployed Cloud Run URL and
      real stream token.
- [x] Twilio media stream endpoint validates one-time stream tokens.
- [x] Call status is written to the cloud call-log database when
      `CALL_LOG_BACKEND=firestore`.

## Phase 10: Verification, Security Audit, And Commits

Status: Completed.

Required checks:

- [x] Run backend lint/tests: `ruff check app tests scripts` and `pytest`.
- [x] Run Flutter checks: `flutter analyze` and relevant `flutter test`.
- [x] Run staged diff checks in each affected repo.
- [x] Run staged secret scan.
- [x] Verify `.env` and `.env.*` remain ignored.
- [x] Verify no raw card data, service-account JSON, API keys, Twilio auth
      tokens, Stripe secret keys, callback numbers, or reservation PII are
      committed.
- [x] Commit backend changes in `wanderlust-backend/`.
- [x] Commit Flutter changes in `wanderlust-frontend-flutter/` if there are
      Flutter changes. No Flutter files changed in Phase 9/10.
- [x] Report commit hashes, test results, security audit result, and residual
      risks.

## Progress Log

- 2026-07-03: Created this living plan from FS Requirement 1. No implementation
  has started yet.
- 2026-07-03: Completed Phase 0 docs alignment. Updated product guardrails,
  backend plan, deployment docs, and agent entrypoint to describe the Actions
  hub, backend-mediated Stripe operations, no raw card storage, and the narrow
  Google Cloud database exception for Twilio call logs. PlantUML update remains
  deferred until the implementation shape is confirmed.
- 2026-07-03: Archived `04-agentic-backend-plan.md` as completed historical
  context so future agents use this plan for new work. Completed Phase 1
  modular architecture scaffolding: added backend action, booking-intake,
  manual-call, Stripe-commerce, and Ask Agent Anything service boundaries; added
  Flutter feature module folders, action catalog, route names, and placeholder
  feature exports. Shared full-page chat extraction remains for the Call Venue
  implementation phase.
- 2026-07-03: Completed Phase 2 itinerary activity Actions entry point. Activity
  cards now show **Directions** and **Actions**. The new `ActivityActionsPage`
  receives itinerary/day/stop/venue context and routes to placeholder Call the
  Venue, Book or Buy Packages, and Ask Agent Anything destination pages. These
  destinations are side-effect-free until their dedicated implementation phases.
- 2026-07-03: Completed Phase 3 and Phase 4. Call the Venue now opens a
  full-page conversational flow with AI booking and manual-call branches,
  step-by-step venue contact/name/future date-time/pax/remarks collection,
  editable script summary, and explicit `Call using agent` confirmation before
  invoking the booking-call API. Backend booking details must require callback
  phone for agent-assisted booking calls; the temporary optional-callback
  direction has been superseded. Twilio call lifecycle events now write minimal
  redacted logs through a call-log repository, with Firestore enabled by
  `CALL_LOG_BACKEND` for Cloud Run and disabled by default locally.
- 2026-07-03: Updated Stripe direction before Phase 5 implementation. Purchase
  now uses backend-created Stripe Checkout Sessions and opens Stripe-hosted
  Checkout in an external browser. Local saved-card UI and local payment history
  are removed from scope. Callback phone is required for agent-assisted booking
  calls.
- 2026-07-03: Superseded the Stripe-only purchase direction with
  activity-scoped **Book or Buy Packages**. The app should find verified
  official/authorized provider checkout options for the current activity and
  open the selected provider checkout externally. Stripe Checkout is used only
  when that provider flow is legitimately Stripe-backed or connected.
- 2026-07-03: Completed Phase 5 and Phase 6. Backend now exposes
  activity-scoped provider package search and guarded provider-checkout handoff
  endpoints. Flutter now shows **Book or Buy Packages**, preloads the top five
  scoped package options, supports explicit search and **More** pagination,
  renders package detail, and opens provider checkout externally after user
  action. The first implementation intentionally does not create arbitrary
  Stripe Checkout Sessions for third-party products. The bottom navigation and
  page title now use **Profile** while preserving reset-preferences behavior
  and avoiding saved-card/payment-history UI. Callback phone was restored as
  required for agent-assisted booking calls.
- 2026-07-03: Completed Phase 7 and Phase 8. Added activity-scoped
  **Ask Agent Anything** backend classification and Flutter full-page chat with
  explicit CTAs to **Call the Venue** and **Book or Buy Packages**. Confirmed
  active-itinerary recovery remains ACTIVE-only, creates pending proposals only
  on deviation signals, requires explicit accept/reject decisions, and does not
  silently mutate itinerary days.
- 2026-07-03: Completed Phase 9 deployment alignment. Fixed Cloud Run deploy
  service-account ordering, aligned Terraform with Firestore call-log API/IAM
  and `CALL_LOG_*` env vars, documented public Twilio HTTPS/WSS endpoints,
  Secret Manager requirements, Cloud Run smoke checks, and live Twilio E2E
  command. Live Cloud Run/Twilio checks still require deployed credentials and
  a public service URL.
- 2026-07-03: Completed Phase 10 final verification. Backend lint passed,
  backend tests passed with the live Twilio E2E test skipped by default, Flutter
  analyze and widget tests passed, `.env` files remain ignored in both repos,
  changed-file secret scan found no matches, and the architecture diagram now
  reflects the implemented Actions hub, Call the Venue, provider checkout,
  Ask Agent Anything, and Cloud Run call-log paths. Terraform CLI was not
  available locally, so Terraform formatting could not be executed in this
  environment; the edited Terraform was manually inspected. Backend deployment
  alignment was committed as `0d9b9d4 Align Cloud Run deployment for call
  logging`; no Flutter files changed during Phase 9/10, and the Flutter repo
  remained clean at `ce07878`.
