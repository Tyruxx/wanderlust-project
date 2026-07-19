# Wanderlust Trip

Wanderlust Trip is an iOS-first Flutter application backed by FastAPI and
Google ADK workflows on Google Cloud Run. Production app state is stored in
Firestore under the anonymous device ID sent as `X-User-Id`. The backend is a
cloud-only runtime; developers run Flutter locally against the deployed HTTPS
service.

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
for Twilio HTTPS/WSS callbacks. Firestore is the production source of truth for
device-scoped backend state.

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
