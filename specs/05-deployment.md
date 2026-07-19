# Deployment

The canonical operator instructions are in the project-root `README.md`. This
spec defines the deployment constraints that implementations and documentation
must preserve.

## Backend Runtime

- The application backend is cloud-only and runs on Google Cloud Run.
- Do not provide or depend on a locally running FastAPI service for Flutter.
- Backend lint and isolated tests may run locally; they are not an application
  runtime.
- Cloud Run exposes every API feature plus the public Twilio HTTPS/WSS
  callbacks required by Gemini Live booking calls.
- The current live-call bridge keeps process-local session state, so production
  remains pinned to one warm Cloud Run instance until external session storage
  is implemented.

## Persistence And Identity

- Firestore is the production backend source of truth.
- Every backend document is scoped by Flutter's anonymous `X-User-Id` device
  ID. This is not login or account identity.
- Flutter stores preferences, itinerary data, cache, and the device ID in its
  application sandbox according to the product guardrails.
- SQLite or in-memory backend repositories exist only for isolated automated
  tests and must not be documented as a supported backend runtime.
- Resetting preferences never resets the anonymous routing ID or deletes saved
  itineraries.

## Cloud Resources

The supported deployment provisions or uses:

- Cloud Run for FastAPI and Google ADK workflows.
- Cloud Build and Artifact Registry for container builds.
- Firestore for device-scoped backend state and redacted booking-call logs.
- Secret Manager for Gemini, Maps backend, and Twilio credentials.
- A dedicated runtime service account with `roles/datastore.user` and narrow
  per-secret access. Broad owner/editor roles are forbidden.

The repository provides two infrastructure paths:

- `wanderlust-backend/scripts/setup_gcp_resources.sh` followed by
  `wanderlust-backend/scripts/deploy_cloud_run.sh` for the recommended direct
  deployment.
- `wanderlust-backend/infra/cloud-run/` for Terraform-managed infrastructure.

Do not operate both paths as competing owners of the same resources without
reconciling Terraform state.

## Secrets

- Local deployment/build values may live only in the ignored
  `wanderlust-backend/.env`.
- Cloud Run receives backend credentials from Secret Manager.
- Flutter receives only the public Cloud Run URL and the iOS-restricted Maps
  key at build time.
- Never commit `.env`, API keys, Twilio credentials, service-account JSON,
  signing certificates, or provisioning profiles.
- The iOS Maps key must be restricted to the production bundle identifier and
  required iOS Maps APIs.

## Flutter Development

- Deploy Cloud Run before running Flutter.
- Every local, Simulator, physical-device, TestFlight, and App Store build must
  receive the same deployed HTTPS service as `PUBLIC_BACKEND_BASE_URL`.
- `BACKEND_BASE_URL` and `CALL_SERVICE_BASE_URL` may resolve to that same URL.
- Localhost backend URLs are unsupported in debug and release builds.
- The iOS app never embeds Python, backend service-account material, Gemini
  keys, Maps backend keys, Twilio credentials, or provider secrets.

## App Store Delivery

- The distributable artifact is one signed Flutter iOS IPA.
- App Store builds must reject missing, localhost, or non-HTTPS backend URLs.
- The bundle identifier must match Apple Developer, App Store Connect, signing,
  and Google Maps iOS restrictions.
- Upload occurs through Xcode Organizer or Apple's Transporter after the IPA is
  built by `wanderlust-frontend-flutter/scripts/build_ios_app_store.sh`.

## Verification

Before release:

```bash
cd wanderlust-backend
.venv/bin/ruff check app tests scripts
env WANDERLUST_DB=memory .venv/bin/python -m pytest

cd ../wanderlust-frontend-flutter
flutter analyze
flutter test
```

Also verify the deployed `/readyz` endpoint, Firestore device scoping, package
search, itinerary generation, routes, Ask Agent Anything, active-only location
events, Twilio callbacks, and booking-call WebSocket status updates against the
same Cloud Run URL used by Flutter.
