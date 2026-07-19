# Deployment

The backend runs standalone locally for development, but production app usage
targets Cloud Run. Production backend app state is device-scoped Firestore
storage keyed by the anonymous `X-User-Id` device ID that Flutter generates on
first launch. SQLite is retained only for local development and tests.

Local development reads `.env`; Cloud Run deployment uses Secret Manager for
API keys, Twilio credentials, and optional Stripe server-side credentials when
a legitimate Stripe-backed provider flow is added.

Twilio call logs are stored in Firestore when the call service runs on Google
Cloud. These logs must be minimal and redacted.

## Local

```bash
cd wanderlust-backend
source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Set env vars in `.env` for real service calls: `GOOGLE_API_KEY` (Gemini),
`GOOGLE_MAPS_BACKEND_API_KEY` (Maps), Twilio/Gemini Live values for booking
calls, and optional Stripe server-side values only for valid Stripe-backed
provider flows. `PUBLIC_BACKEND_BASE_URL`
must be a public HTTPS URL for Twilio webhook/WSS callbacks.

## Production (Cloud Run)

Cloud Run provides the public HTTPS/WSS endpoint required by all backend
features and by Twilio Media Streams/Gemini Live booking calls. The mobile app
remains no-login: it generates a local anonymous `anon_...` device ID and sends
it as `X-User-Id` for backend routing and Firestore device-scoped storage.

For a production-ready setup, use `../PRODUCTION_SETUP.md` as the operator
checklist. The summary is: prepare GCP resources, add Secret Manager versions,
deploy Cloud Run, then build the iOS app with the Cloud Run URL as
`PUBLIC_BACKEND_BASE_URL`.

1. Prepare required Google Cloud resources:

```bash
cd wanderlust-backend
GOOGLE_CLOUD_PROJECT="$PROJECT_ID" \
GOOGLE_CLOUD_REGION=asia-southeast1 \
./scripts/setup_gcp_resources.sh
```

The setup script enables Cloud Run, Cloud Build, Artifact Registry, Firestore,
Secret Manager, Vertex AI/Gemini, and the Google Maps Platform APIs used by the
backend. It creates the runtime service account, Artifact Registry repository,
default Firestore database when missing, and required Secret Manager secrets
when missing. It grants only `roles/datastore.user` plus per-secret accessor
permissions to the Cloud Run service account.

2. Add or rotate required Secret Manager secret versions:

```bash
printf '%s' "$GOOGLE_API_KEY" | gcloud secrets versions add google-api-key --data-file=-
printf '%s' "$GOOGLE_MAPS_BACKEND_API_KEY" | gcloud secrets versions add google-maps-backend-api-key --data-file=-
printf '%s' "$TWILIO_ACCOUNT_SID" | gcloud secrets versions add twilio-account-sid --data-file=-
printf '%s' "$TWILIO_AUTH_TOKEN" | gcloud secrets versions add twilio-auth-token --data-file=-
printf '%s' "$TWILIO_FROM_NUMBER" | gcloud secrets versions add twilio-from-number --data-file=-
```

3. Deploy with the script:

```bash
cd wanderlust-backend
GOOGLE_CLOUD_PROJECT="$PROJECT_ID" \
GOOGLE_CLOUD_REGION=asia-southeast1 \
./scripts/deploy_cloud_run.sh
```

The script builds the image, deploys Cloud Run, and updates
`PUBLIC_BACKEND_BASE_URL` to the generated service URL unless a custom public
URL is supplied. The current booking-call bridge keeps live session state in
process memory, so Cloud Run is pinned to one warm instance until external
session storage is added.

Production app-state storage uses Firestore when
`WANDERLUST_STORAGE_BACKEND=firestore` and stores repository documents under
collections prefixed by `FIRESTORE_COLLECTION_PREFIX` (default `wanderlust`).
Cloud call logging uses Firestore when `CALL_LOG_BACKEND=firestore` and stores
status-transition events under `CALL_LOG_COLLECTION` (default:
`wanderlust_booking_call_logs`). The deploy script and Terraform grant
`roles/datastore.user` to the Cloud Run service account; do not grant broad
project-owner permissions for this path.

4. Or deploy with Terraform:

```bash
cd wanderlust-backend
IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/wanderlust/wanderlust-backend:$(git rev-parse --short HEAD)"
gcloud builds submit --project "$PROJECT_ID" --tag "$IMAGE" .
cd infra/cloud-run
terraform init
terraform apply -var="project_id=$PROJECT_ID" -var="region=$REGION" -var="image=$IMAGE"
```

5. Point the Flutter app at the deployed URL:

```bash
flutter run --dart-define=PUBLIC_BACKEND_BASE_URL="$CLOUD_RUN_URL" \
  --dart-define=BACKEND_BASE_URL="$CLOUD_RUN_URL" \
  --dart-define=GOOGLE_MAPS_IOS_API_KEY="$GOOGLE_MAPS_IOS_API_KEY"
```

6. Verify the deployed backend:

```bash
curl "$CLOUD_RUN_URL/readyz"
```

Twilio must be able to reach these public endpoints:

- `POST/GET $CLOUD_RUN_URL/v1/booking-calls/twiml/{stream_token}`
- `WSS wss://.../v1/booking-calls/stream/{stream_token}`
- `POST $CLOUD_RUN_URL/v1/booking-calls/twilio-status`

For an end-to-end live call smoke test, use a safe Twilio-verified destination
number:

```bash
cd wanderlust-backend
WANDERLUST_RUN_TWILIO_E2E=1 \
WANDERLUST_TWILIO_E2E_TO_NUMBER="+15551234567" \
.venv/bin/python -m pytest tests/test_twilio_e2e.py
```

## Flutter

```bash
# From project root:
flutter run --dart-define=GOOGLE_MAPS_IOS_API_KEY="$GOOGLE_MAPS_IOS_API_KEY"
```

Defaults to `BACKEND_BASE_URL=http://127.0.0.1:8000`. Override via
`--dart-define=BACKEND_BASE_URL=...` to point at a deployed backend.
For the normal local stack, prefer `./start.sh` from the project root. It reads
`PUBLIC_BACKEND_BASE_URL` or `CALL_SERVICE_BASE_URL` from `wanderlust-backend/.env` and
passes it to Flutter as `CALL_SERVICE_BASE_URL`, so the local UI can route
booking-call start/status requests to the cloud call service without redefining
the value on every launch.

The app generates and persists an anonymous local device ID once per install.
This ID contains no personal details and is sent as `X-User-Id` on backend
requests. Resetting travel preferences must not reset this routing ID.

## App Store IPA

The App Store artifact is a single iOS app IPA. The IPA contains the Flutter
frontend and local SQLite persistence, but it must not bundle the Python/FastAPI
backend, service-account material, Twilio credentials, Gemini keys, or Stripe
provider secrets. Those server-side capabilities run on the deployed HTTPS
backend/call service.

Use the frontend build helper:

```bash
cd wanderlust-frontend-flutter
./scripts/build_ios_app_store.sh
```

Required build-time values:

- `BACKEND_BASE_URL` or `PUBLIC_BACKEND_BASE_URL`: deployed HTTPS backend URL.
- `CALL_SERVICE_BASE_URL`: optional; defaults to the backend URL.
- `GOOGLE_MAPS_IOS_API_KEY`: iOS-restricted Maps key for on-device map rendering.

The build helper refuses localhost backend URLs. In an installed iOS app,
`127.0.0.1` would point to the user's device and the backend-dependent features
would fail.

## CI Checks

```bash
python -m pytest tests/
ruff check app tests scripts
```
