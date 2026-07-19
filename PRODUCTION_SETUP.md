# Wanderlust Production Setup

Use this guide when preparing a real iOS/TestFlight/App Store build. The
production topology is:

- Flutter iOS app: one installable app binary.
- Backend: FastAPI/Google ADK service on Google Cloud Run.
- Storage: Firestore, scoped by Flutter's anonymous `X-User-Id` device ID.
- Calls: Twilio webhooks and media streams route to the same Cloud Run URL.
- Secrets: Secret Manager only. Do not put backend secrets in the Flutter app.

## 1. Prerequisites

- Google Cloud project with billing enabled.
- `gcloud` authenticated to the target project.
- Docker/Cloud Build permission for Artifact Registry.
- Flutter/Xcode signing configured for the iOS app.
- Twilio account with outbound voice permissions enabled for target countries.
- Google Maps iOS API key restricted to the iOS bundle ID.

## 2. Prepare Google Cloud Resources

From the project root:

```bash
cd wanderlust-backend
GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID" \
GOOGLE_CLOUD_REGION="asia-southeast1" \
./scripts/setup_gcp_resources.sh
```

The script enables required Google APIs, creates the Cloud Run service account,
creates Artifact Registry, creates Firestore if needed, creates required Secret
Manager secrets if missing, and grants the Cloud Run service account only the
Firestore and secret-access permissions it needs.

## 3. Add Secret Versions

Add the values you already prepared:

```bash
printf '%s' "$GOOGLE_API_KEY" | gcloud secrets versions add google-api-key --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$GOOGLE_MAPS_BACKEND_API_KEY" | gcloud secrets versions add google-maps-backend-api-key --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$TWILIO_ACCOUNT_SID" | gcloud secrets versions add twilio-account-sid --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$TWILIO_AUTH_TOKEN" | gcloud secrets versions add twilio-auth-token --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
printf '%s' "$TWILIO_FROM_NUMBER" | gcloud secrets versions add twilio-from-number --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
```

## 4. Deploy Backend To Cloud Run

```bash
cd wanderlust-backend
GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID" \
GOOGLE_CLOUD_REGION="asia-southeast1" \
./scripts/deploy_cloud_run.sh
```

The script prints the deployed Cloud Run URL. Keep that URL; it is the single
production backend URL for planning, itinerary CRUD, package search, Ask Agent
Anything, booking calls, route computation, active events, and Twilio callbacks.

Verify it:

```bash
CLOUD_RUN_URL="https://YOUR_CLOUD_RUN_SERVICE_URL"
curl "$CLOUD_RUN_URL/readyz"
```

## 5. Configure Twilio

The backend generates per-call TwiML and media-stream URLs. Use the Cloud Run
URL as the public base URL. Twilio must be able to reach:

- `$CLOUD_RUN_URL/v1/booking-calls/twiml/{stream_token}`
- `wss://.../v1/booking-calls/stream/{stream_token}`
- `$CLOUD_RUN_URL/v1/booking-calls/twilio-status`

For normal app usage, the app starts calls through the backend API; you do not
hardcode a static stream token in Twilio.

## 6. Build The iOS App

Set `PUBLIC_BACKEND_BASE_URL` to the Cloud Run URL. The call service defaults
to the same URL, so you only need one backend link.

```bash
cd wanderlust-frontend-flutter
PUBLIC_BACKEND_BASE_URL="https://YOUR_CLOUD_RUN_SERVICE_URL" \
GOOGLE_MAPS_IOS_API_KEY="YOUR_IOS_RESTRICTED_MAPS_KEY" \
./scripts/build_ios_app_store.sh
```

The script refuses localhost and non-HTTPS backend URLs for App Store builds.

## 7. Smoke Test

Before distribution:

```bash
cd wanderlust-backend
.venv/bin/python -m pytest tests/test_booking_calls.py tests/test_api_routes.py tests/test_guardrails.py
.venv/bin/ruff check app tests scripts

cd ../wanderlust-frontend-flutter
flutter analyze
flutter test
```

For a live Twilio smoke test, use only a safe verified destination:

```bash
cd ../wanderlust-backend
WANDERLUST_RUN_TWILIO_E2E=1 \
WANDERLUST_TWILIO_E2E_TO_NUMBER="+15551234567" \
.venv/bin/python -m pytest tests/test_twilio_e2e.py
```

## Production Notes

- Do not deploy with `BACKEND_BASE_URL=http://127.0.0.1:8000` for iOS builds.
- Do not commit `.env`, service-account JSON, Twilio credentials, or API keys.
- Keep Cloud Run max instances at `1` while live call session state is
  process-local.
- Firestore is the production backend source of truth for device-scoped backend
  state. SQLite is for local development/tests only.
- Flutter still stores local preferences/cache, but backend features use
  Cloud Run + Firestore in production.
