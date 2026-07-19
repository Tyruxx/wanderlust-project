# Archived Agentic Backend Plan And Progress Log

This document is archived. It records the completed backend implementation
history up through the ADK planning/chat/booking-call work, but it is no longer
the active handoff source of truth for new feature development.

Future agents must not use this document as the current execution plan. For the
current Actions, venue-call, provider checkout, optional Stripe-backed checkout, Profile rename, cloud
call-log, and Ask Agent Anything work, use:

- `06-actions-commerce-call-plan.md`

## Completed Goal

Build a separate backend in `wanderlust-backend/`
for the Flutter app in `wanderlust-frontend-flutter/`.

The backend will use FastAPI plus Google ADK 2.0. It must enforce the product
guardrails in `specs/03-product-workflows-and-guardrails.md` before invoking
agents or external tools.

Security development guidance lives in
`../skills/wanderlust-agentic-security/SKILL.md` and must be loaded before
changing agent workflows, ADK tools, prompts, MCP/tool integrations,
external-source ingestion, secrets, deployment, persistence, or ACTIVE
itinerary event handling.

## Completed Architecture Snapshot

> Historical note: this archived plan described the earlier local-only backend
> storage decision. The current production direction supersedes that decision:
> Cloud Run hosts backend features and Firestore stores backend app state scoped
> by the anonymous `X-User-Id` device ID. SQLite remains the local dev/test
> fallback.

- Flutter iOS client keeps local cached state and the anonymous device ID.
- Production backend storage is Firestore, scoped by `X-User-Id`; local
  development and tests may use SQLite.
- Google Cloud is only used for external API calls: Gemini/Vertex AI (via ADK),
  Gemini Google Search grounding, and Google Maps Platform.
- FastAPI receives explicit request context (X-User-Id header) from Flutter.
- Google ADK graph workflows generate and verify itineraries.
- Google ADK ambient/event workflows process ACTIVE itinerary location and deviation events only.
- Google ADK `ParallelAgent` and `SequentialAgent` patterns are used for
  retrieval fanout and ordered planning/booking stages, with deterministic
  FastAPI services retaining side-effect and schema guardrails.
- Location events are handled by the backend active-event service and persisted
  through the configured backend repository.
- API keys are read from `.env` directly for local development and injected
  from Secret Manager on Cloud Run.

## Superseded Directions

- **Identity provider**: Superseded. There is no end-user identity-provider requirement. Backend uses `X-User-Id` header only.
- **Local-only storage**: Superseded for production. Firestore is used for
  Cloud Run backend app state; SQLite remains for local development and tests.

## Functional Completion Bar At Archive Time

- Flutter completes local preference onboarding before the first itinerary generation.
- Flutter sends explicit trip, preference, itinerary, and ACTIVE-event context to FastAPI via `X-User-Id` header.
- Production backend state persists in Firestore under anonymous device scope;
  local development and tests may use SQLite.
- Itinerary generation calls Google ADK/Vertex AI, Gemini Google Search grounding,
  and real Google Maps Platform APIs.
- ACTIVE itinerary events are logged locally and trigger ACTIVE-only backend handling.
- API keys are read from `.env` file locally and from Secret Manager on Cloud Run.
- Backend runs locally with `uvicorn`; Cloud Run is used when Twilio needs public webhook/WSS endpoints.

## Required Environment Values

Minimum values before real service calls:

- `GOOGLE_API_KEY` — for Gemini API access and Google Search grounding (or Vertex AI via ADC with `GOOGLE_CLOUD_PROJECT` for planner calls)
- `GOOGLE_MAPS_BACKEND_API_KEY` — for backend Places, Routes, Geocoding, and Weather calls
- `GOOGLE_MAPS_IOS_API_KEY` — for Maps SDK for iOS / Flutter map UI calls
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`,
  `PUBLIC_BACKEND_BASE_URL` — for confirmed agent-assisted booking calls
- `GEMINI_LIVE_MODEL` — for the Gemini Live voice model used by booking calls

## Guardrail Checklist

- [x] Local preference onboarding required before first itinerary generation.
- [x] Preferences stored as structured data, not Markdown-only.
- [x] Preference changes increment a version and affect future agent runs.
- [x] Reset preferences erases local preferences and saved itinerary preference patterns, returns to onboarding, and does not delete saved itineraries.
- [x] Only one itinerary may be ACTIVE.
- [x] Starting another itinerary requires explicit replacement.
- [x] INACTIVE and COMPLETED itineraries reject active location/event ingestion.
- [x] Stop and complete halt location, ambient workflows, suggestions, and dynamic behavior updates.
- [x] Agent chat cannot silently activate, stop, delete, export, book, or buy.
- [x] Agent chat applies only simple validated edits directly; whole-day or whole-trip rewrites remain proposal-only until user acceptance.
- [x] Itinerary recovery proposals require user acceptance before applying.
- [x] Recommendations include explanation/reasoning and source confidence.
- [x] Google Search grounding output is treated as untrusted evidence and validated before itinerary persistence.
- [x] Social sources are discovery signals only, never factual authority.
- [x] Booking, payment, and calls require explicit confirmation.
- [x] Booking calls collect per-request reservation details, use Twilio only
  after explicit confirmation, and fall back to chat instructions when call
  infrastructure or venue phone lookup is unavailable.

## Implementation Steps

### Step 1–7: History

Steps 1–7 were completed under earlier architectural decisions that included
Firestore, Pub/Sub, and Secret Manager-backed app storage. Firestore and Pub/Sub
have since been removed in favor of local-only storage; Secret Manager remains
only for Cloud Run secret injection. The implementation details of those steps
are retained in git history but no longer reflect current architecture.

### Step 7a: Remove Superseded Identity Scaffolding

Status: Completed.

Removed provider-specific identity scaffolding and switched to the `X-User-Id`
device context header. See git log for details.

### Step 7b: Local-Only Storage (Remove Firestore And Pub/Sub)

Status: Completed historically, then superseded for production by Cloud
Run + Firestore device-scoped storage.

Deliverables:

- Replaced `FirestoreRepository` with `SqliteRepository` backed by stdlib sqlite3.
- Replaced `PubSubLocationEventPublisher` with `LocalLocationEventPublisher` that logs events instead of publishing.
- Removed `google-cloud-firestore`, `google-cloud-pubsub`, `google-cloud-secret-manager` from `pyproject.toml`.
- Removed `firestore_database_id` and `pubsub_*_topic` fields from `Settings`.
- Removed `GOOGLE_CLOUD_PROJECT` from `missing_required_values` (no longer required for local runtime).
- Updated `.env` to remove Firestore/PubSub references.
- Removed `Field` import from `settings.py` (no longer used).

Backend still starts locally with SQLite for development and tests. Production
Cloud Run uses Firestore for backend app-state persistence.

Verification:

- Backend starts with `uvicorn` and responds on `/readyz` without any Google Cloud credentials.
- Ruff passes for `app`, `tests`, `scripts`.
- Tests updated to use `SqliteRepository` (in-memory SQLite auto-detected).

### Step 8: End-To-End Functional Validation

Status: Pending.

Planned deliverables:

- Complete local preference onboarding in the Flutter app.
- Run the Flutter app against the running backend and verify itinerary generation, lifecycle actions, and location events.
- Verify all state survives backend process restarts only through Flutter's local persistence and backend SQLite.
- Produce a handoff runbook with exact commands, required env values, and known limitations.

### Step 7c: Hybrid Maps + Google Search Planning And Expanded Chat

Status: Completed.

Deliverables:

- Added a parallel retrieval fanout for itinerary generation: Maps place search,
  weather/geocode context, and bounded Gemini Google Search grounding agents.
- Added specialist search lanes for food, culture, current events/openings,
  logistics, and hidden gems; results are deduped, ranked, and converted into
  source evidence before planner synthesis.
- Expanded chat action handling for route-gap insertion, timing edits,
  transport-mode edits, recommendation-only responses, and proposal-only
  itinerary rewrites.
- Preserved guardrails: chat cannot trigger lifecycle, commerce, export, or
  booking actions, and major rewrites require explicit frontend acceptance.
- Updated `agentic-architecture.puml` to show the parallel retrieval and chat
  proposal flows.

## Progress Log

- Step 1–7 completed (see git history for details).
- Step 7a completed: provider-specific identity scaffolding removed, X-User-Id header adopted.
- Step 7b completed historically, then superseded for production: Cloud Run now
  uses Firestore for backend app state scoped by anonymous `X-User-Id`.
- Step 7c completed: hybrid Maps + Gemini Google Search grounding retrieval added, expanded chat actions implemented, and architecture diagram updated.

### Step 7d: Booking Calls And ADK Workflow Refactor

Status: Completed.

Deliverables:

- Added ADK workflow objects for planning, parallel specialist search, chat
  classification, and booking intake/voice stages.
- Added per-activity booking chat flow with booking-call offers, fallback
  instructions, and explicit call confirmation.
- Added Twilio outbound call creation, TwiML callback, status callback, and
  secured media-stream endpoint with one-time stream tokens.
- Added Gemini Live bridge shell and deterministic audio conversion boundary;
  incomplete call infrastructure degrades to instructional chat fallback.
- Added Google Places phone lookup for booking-call eligibility.
