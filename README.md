# Wanderlust Trip

Wanderlust Trip is an iOS-first Flutter application backed by FastAPI and
Google ADK workflows on Google Cloud Run. **Your itineraries and preferences
never leave your device** — all frontend state is stored in local SQLite.
The backend uses Firestore only for its own operational context (AI generation
state, location events) under the anonymous device ID sent as `X-User-Id`.
The backend is a cloud-only runtime; developers run Flutter locally against the
deployed HTTPS service.

## Problem Statement

Travel planning is rarely linear. Travelers describe goals loosely, discover
places across fragmented sources, change their minds, encounter closures or
delays, and drift away from the original schedule. Traditional itinerary apps
treat the plan as fixed, while many AI planners stop being useful after they
generate a generic list of places.

That leaves several practical problems:

- Recommendations may be stale, geographically inefficient, or disconnected
  from the traveler's actual interests and time constraints.
- A delay, skipped stop, or route change can make the rest of a day unrealistic.
- Booking contacts, packages, transport options, and current venue information
  are scattered across unrelated services.
- Social and web discovery can surface useful ideas, but those claims may be
  inaccurate, sponsored, outdated, or unsafe to trust without verification.
- Location-aware assistance is useful only when collection, active-mode
  behavior, and user acceptance are explicit and understandable.

Wanderlust addresses this by turning natural-language trip intent into a
grounded, route-aware itinerary, then remaining useful during the trip. It can
research places, compare transport options, answer activity-specific questions,
find verified provider links, assist with venue calls, and propose itinerary
recovery when an ACTIVE trip deviates from plan. Agents investigate and reason,
but lifecycle changes, persistence, calls, purchases, and itinerary rewrites
remain behind typed validation and explicit user action.

The product promise is: **plan with an agent, then let the agent adapt with you
while you travel without surrendering control.**

## App Architecture

Wanderlust uses a local-first Flutter client with a cloud-only backend. **All
itineraries, preferences, and trip history are stored exclusively in local
SQLite — they never touch the cloud.** Flutter owns the mobile experience, map
interaction, location permissions, and explicit confirmation UI. Cloud Run
hosts FastAPI, Google ADK workflows, deterministic policy gates, and
integrations that require protected server credentials. The backend uses
Firestore only for its own operational state (AI generation context, location
events) under an anonymous device scope, not for user itineraries or
preferences. Only AI itinerary generation and active-location events reach the
backend; preference and itinerary lifecycle management is fully offline.

```mermaid
flowchart TB
    User[Traveler] --> Flutter[Flutter iOS app]
    Flutter -->|HTTPS and X-User-Id| API[FastAPI on Cloud Run]

    API --> Guards[Typed schemas and deterministic guardrails]
    Guards --> Planner[ADK planning workflow]
    Guards --> Actions[ADK activity action workflows]
    Guards --> Active[ACTIVE itinerary event workflow]

    Planner --> Intake[Sequential intake and normalization]
    Intake --> Retrieval[Parallel retrieval fan-out]
    Retrieval --> Maps[Places, Routes, Geocoding, Weather]
    Retrieval --> Search[Grounded search specialist agents]
    Maps --> Verify[Merge, dedupe, rank, and verify]
    Search --> Verify
    Verify --> Synthesis[Planner synthesis]

    Actions --> Ask[Ask Agent Anything]
    Actions --> Packages[Package discovery and link verification]
    Actions --> Booking[Booking intake and locale resolution]

    Booking --> Twilio[Twilio Programmable Voice]
    Booking --> Live[Gemini Live voice bridge]
    Packages --> Providers[Official and authorized providers]

    Guards --> Firestore[(Firestore backend operational state)]
    Synthesis --> Firestore
    Active --> Firestore
    Firestore --> API

    API --> Secrets[Secret Manager]
    Flutter --> Local[(Local SQLite — itineraries, preferences, cache)]
```

### Modular Agentic Design

The backend separates reasoning from authority so agents can be specialized
without receiving unrestricted control:

- **Planning orchestration** uses sequential stages for intake, verification,
  and synthesis, with bounded parallel retrieval for independent Maps, weather,
  and grounded-search work.
- **Specialist retrieval agents** focus on food, culture, current events,
  logistics, and hidden gems. Their outputs are evidence, never instructions.
- **Merge and verification modules** normalize candidates, preserve citations,
  remove duplicates, score freshness and relevance, and reject unsupported
  claims before planner synthesis.
- **Activity action modules** isolate informational Q&A, package discovery,
  booking intake, venue-contact resolution, and language selection rather than
  routing every request through one oversized agent.
- **ACTIVE itinerary modules** process location/deviation events only through
  lifecycle and permission gates, and return recovery proposals that require
  acceptance instead of silently rewriting an itinerary.
- **Deterministic services remain authoritative** for schemas, persistence,
  one-ACTIVE-itinerary enforcement, URL allowlisting, source checks, call
  confirmation, PII scrubbing, and all external side effects.
- **Graceful degradation** allows one retrieval lane to fail without inventing
  evidence or collapsing the entire workflow; unavailable capabilities return
  bounded fallbacks or clear user-facing errors.

### ADK Planning Workflow

The planning path combines ADK agent roles with deterministic orchestration.
The ADK workflow registry defines a sequential intake → discovery → verification
→ planner pipeline and parallel grounded-search specialists. The planning
service controls execution, joins evidence, validates every model result, and
enforces product rules before the itinerary is returned to Flutter.

```mermaid
flowchart TD
    Click["User taps Generate itinerary"] --> Submit["Flutter sends trip brief,<br/>preferences, and day rules"]
    Submit --> Validate["FastAPI validates<br/>the request schema"]
    Validate --> Intake["Intake agent normalizes<br/>planning constraints"]
    Intake --> FanOut{"Gather evidence<br/>in parallel"}

    subgraph Retrieval[Parallel retrieval]
        Maps["Maps lane<br/>Places and geocoding"]
        Weather["Weather lane<br/>Current weather and forecast"]
        Search["ADK ParallelAgent<br/>5 grounded specialists"]
    end

    FanOut --> Maps
    FanOut --> Weather
    FanOut --> Search

    Maps --> Merge["Merge and dedupe<br/>all candidates"]
    Weather --> Merge
    Search --> Merge

    Merge --> Verify["Verification agent checks<br/>sources and confidence"]
    Verify --> Plan["Planner agent creates<br/>the day-by-day itinerary"]
    Plan --> Guard["Validate output and enforce<br/>times, places, and guardrails"]
    Guard --> Response["FastAPI returns the validated<br/>itinerary and evidence"]
    Response --> Display["Flutter displays the<br/>AI-generated itinerary"]
```

This diagram begins when the traveler presses **Generate itinerary** and ends
when Flutter receives and displays the result. It intentionally excludes later
status changes such as starting the itinerary. Planner JSON must pass typed
validation, mandatory trip rules, generic-place filtering, and recommendation
guardrails before the API returns it to Flutter.

This structure keeps agents independently testable and replaceable while the
public API contracts, safety boundaries, and storage model remain stable.

## Repository Layout

- `wanderlust-backend/` - FastAPI, Google ADK, Cloud Run, Firestore, Maps,
  Gemini, Twilio, and Terraform code.
- `wanderlust-frontend-flutter/` - Flutter iOS application.
- `specs/` - product requirements, guardrails, architecture, and deployment
  constraints.
- `skills/` - project execution, frontend, and agentic-security instructions.

Clone the parent repository with both child repositories:

```bash
git clone --recurse-submodules https://github.com/Tyruxx/wanderlust-project.git
cd wanderlust-project
```

For an existing clone, initialize or refresh the children with:

```bash
git submodule update --init --recursive
```

## Prerequisites

- A Google Cloud project with billing enabled.
- `gcloud` authenticated with permission to manage Cloud Run, Cloud Build,
  Artifact Registry, Firestore, Secret Manager, service accounts, and required
  APIs.
- Flutter, Xcode, CocoaPods, and an Apple Developer account.
- A Twilio account with outbound voice permission for the destination regions.
- Backend service credentials already stored in
  `wanderlust-backend/.env`; this file is ignored and must never be committed.
- An iOS-restricted Google Maps key for the production bundle identifier.

## Deploy The Backend To Google Cloud

The backend is not run locally. Cloud Run is required for all API features and
for Twilio HTTPS/WSS callbacks. Firestore stores backend-only operational state
(AI generation context, location events); user itineraries and preferences
never leave the device.

### 1. Authenticate And Select The Project

```bash
gcloud auth login
gcloud auth application-default login

export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
export GOOGLE_CLOUD_REGION="asia-southeast1"
gcloud config set project "$GOOGLE_CLOUD_PROJECT"
```

### 2. Load The Local Deployment Values

Load the ignored environment file into the current shell. Do this only with a
trusted local file:

```bash
cd wanderlust-backend
set -a
source .env
set +a

export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
export GOOGLE_CLOUD_REGION="asia-southeast1"
```

`GOOGLE_MAPS_IOS_API_KEY` is used only while building Flutter. Backend secrets
are copied into Secret Manager and are never embedded in the app.

### 3. Create Cloud Resources

```bash
./scripts/setup_gcp_resources.sh
```

The script enables the required APIs and creates the runtime service account,
Artifact Registry repository, Firestore database, and Secret Manager entries.
It grants the runtime account narrow Firestore and per-secret access.

### 4. Add Or Rotate Secret Versions

```bash
printf '%s' "$GOOGLE_API_KEY" | gcloud secrets versions add google-api-key --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$GOOGLE_MAPS_BACKEND_API_KEY" | gcloud secrets versions add google-maps-backend-api-key --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$TWILIO_ACCOUNT_SID" | gcloud secrets versions add twilio-account-sid --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$TWILIO_AUTH_TOKEN" | gcloud secrets versions add twilio-auth-token --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$TWILIO_FROM_NUMBER" | gcloud secrets versions add twilio-from-number --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
```

### 5. Build And Deploy Cloud Run

```bash
./scripts/deploy_cloud_run.sh
```

The script builds the checked-out backend source with Cloud Build, deploys it to
Cloud Run, configures Firestore-backed state and call logs, and prints the
service URL. Save that URL in the ignored environment file:

```dotenv
PUBLIC_BACKEND_BASE_URL=https://YOUR_CLOUD_RUN_SERVICE_URL
BACKEND_BASE_URL=https://YOUR_CLOUD_RUN_SERVICE_URL
CALL_SERVICE_BASE_URL=https://YOUR_CLOUD_RUN_SERVICE_URL
```

Verify the deployment:

```bash
export PUBLIC_BACKEND_BASE_URL="$(gcloud run services describe wanderlust-backend \
  --project "$GOOGLE_CLOUD_PROJECT" \
  --region "$GOOGLE_CLOUD_REGION" \
  --format 'value(status.url)')"

curl "$PUBLIC_BACKEND_BASE_URL/readyz"
```

Twilio calls use the same Cloud Run service for TwiML, status callbacks, and
the Gemini Live media WebSocket. Keep Cloud Run at one warm instance while
live call session state remains process-local.

### Terraform Alternative

Use Terraform instead of the deployment script when infrastructure should be
managed declaratively:

```bash
cd infra/cloud-run
terraform init
terraform fmt -check
terraform plan \
  -var="project_id=$GOOGLE_CLOUD_PROJECT" \
  -var="region=$GOOGLE_CLOUD_REGION" \
  -var="image=YOUR_ARTIFACT_REGISTRY_IMAGE"
terraform apply \
  -var="project_id=$GOOGLE_CLOUD_PROJECT" \
  -var="region=$GOOGLE_CLOUD_REGION" \
  -var="image=YOUR_ARTIFACT_REGISTRY_IMAGE"
```

Do not use the shell deploy script and Terraform as simultaneous owners of the
same Cloud Run service without reconciling Terraform state.

## Run Flutter Locally

Flutter runs locally while every backend request goes to Cloud Run:

```bash
cd wanderlust-frontend-flutter
flutter pub get

set -a
source ../wanderlust-backend/.env
set +a

flutter run \
  --dart-define="PUBLIC_BACKEND_BASE_URL=$PUBLIC_BACKEND_BASE_URL" \
  --dart-define="BACKEND_BASE_URL=$PUBLIC_BACKEND_BASE_URL" \
  --dart-define="CALL_SERVICE_BASE_URL=$PUBLIC_BACKEND_BASE_URL" \
  --dart-define="GOOGLE_MAPS_IOS_API_KEY=$GOOGLE_MAPS_IOS_API_KEY"
```

Select an iOS Simulator or a signed physical iPhone when Flutter prompts for a
device. A backend URL is mandatory; localhost is intentionally unsupported.

Run frontend verification with:

```bash
flutter analyze
flutter test
```

Backend unit tests and lint may run locally, but the backend service itself is
not started locally:

```bash
cd ../wanderlust-backend
.venv/bin/ruff check app tests scripts
env WANDERLUST_DB=memory .venv/bin/python -m pytest
```

## Build And Upload To The App Store

### 1. Configure Apple Distribution

1. Use a unique production bundle identifier in Xcode and register it in the
   Apple Developer portal.
2. Add the same app in App Store Connect.
3. Select the Apple Developer team under Runner signing settings.
4. Restrict `GOOGLE_MAPS_IOS_API_KEY` to that exact bundle identifier and the
   required iOS Maps APIs.
5. Update the Flutter `version` in `pubspec.yaml` for every submission.

### 2. Build The IPA

The build helper reads the Cloud Run URL and iOS Maps key from
`wanderlust-backend/.env` and refuses localhost or non-HTTPS backend URLs:

```bash
cd wanderlust-frontend-flutter
./scripts/build_ios_app_store.sh
```

The resulting archive and IPA are written under `build/ios/`.

### 3. Upload

Upload using either method:

- Open `build/ios/archive/Runner.xcarchive` in Xcode Organizer, choose
  **Distribute App**, then **App Store Connect** and **Upload**.
- Open Apple's Transporter app and upload the generated file from
  `build/ios/ipa/`.

After processing completes in App Store Connect, finish export compliance,
privacy details, screenshots, review notes, pricing, and release settings
before submitting the build for review.

## Security Rules

- Never commit `.env`, `.env.*`, API keys, service-account JSON, certificates,
  provisioning profiles, or Twilio credentials.
- Keep backend keys in Secret Manager and keep the iOS Maps key restricted to
  the production bundle identifier and required APIs.
- Do not embed the Python backend, service-account credentials, Gemini keys,
  Maps backend key, or Twilio credentials in the iOS application.
- Booking calls, purchases, itinerary rewrites, lifecycle changes, and exports
  remain behind explicit user action and deterministic backend validation.
