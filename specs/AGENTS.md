# Wanderlust Agent Instructions And Specs Index

This is the canonical entrypoint for AI agents working on Wanderlust Trip.
Read this file before making architectural, implementation, security, testing,
or documentation decisions.

Before doing Wanderlust Trip development work, load and follow:

- `../skills/wanderlust-execution-workflow/SKILL.md`

Before changing backend agent workflows, ADK tools, prompts, MCP/tool integrations,
external-source ingestion, ACTIVE itinerary event handling, persistence,
deployment, model-output handling, or API key handling, also load and follow:

- `../skills/wanderlust-agentic-security/SKILL.md`

## Spec File Index

| File | Purpose | Key Topics | Audience |
|------|---------|------------|----------|
| `00-product-problem-statement.md` | Problem definition, target audience, product concept | problem statement, user personas, privacy modes, MVP thesis | Product, Engineering |
| `01-agentic-architecture-approaches.md` | Architecture evaluation and ADK 2.0 design decisions | agent orchestration, ADK graph workflows, agent decomposition, planning vs ambient, state management | Engineering, Architecture |
| `02-mvp-roadmap-risks.md` | MVP scope, timeline, risk register | MVP features, release criteria, risk register, dependencies | Product, PM |
| `03-product-workflows-and-guardrails.md` | Source-of-truth product constraints | preference onboarding, itinerary lifecycle, active mode, recommendation rules, reset behavior, data model | Engineering, QA, Agents |
| `04-agentic-backend-plan.md` | Archived completed backend plan and progress log | historical FastAPI/ADK implementation, completed local SQLite backend, completed booking-call work | Backend Engineering, Agents |
| `05-deployment.md` | Local and production deployment | local setup, Cloud Run, Flutter config, CI checks | Engineering, DevOps |
| `06-actions-commerce-call-plan.md` | Living plan for activity Actions, venue calls, package checkout, and Ask Agent Anything | Actions CTA, call venue, provider checkout, optional Stripe-backed checkout, Profile rename, cloud call logs, verification | Product, Engineering, QA, Agents |
| `agentic-architecture.puml` | PlantUML architecture diagram | system context, component relationships | Architecture |

## Required Reads

- `03-product-workflows-and-guardrails.md` — product guardrails and constraints.
- `04-agentic-backend-plan.md` — archived historical backend plan. Do not use
  it as the active execution plan for new feature work.
- `05-deployment.md` — deployment instructions.
- `06-actions-commerce-call-plan.md` — required before implementing the
  itinerary activity Actions flow, venue calls, package checkout, or Ask Agent
  Anything.

## When Each File Is Relevant

Read first for any task:

- `../skills/wanderlust-execution-workflow/SKILL.md` — required execution workflow for development tasks: inspect specs, preserve user changes, verify guardrails, run security audit, commit, then report.
- `03-product-workflows-and-guardrails.md` — always read before writing screens, APIs, agents, or data models.

Before backend changes:

- `06-actions-commerce-call-plan.md` — active implementation plan for current
  Actions, call, commerce, and Ask Agent Anything work.
- `04-agentic-backend-plan.md` — historical context only.
- `05-deployment.md` — if modifying deployment or env configuration.
- `../skills/wanderlust-agentic-security/SKILL.md` — required before agent workflow, ADK tool, prompt, MCP/tool integration, external-source ingestion, ACTIVE itinerary event, or API key changes.

Before architecture decisions:

- `01-agentic-architecture-approaches.md` — trade-offs, agent decomposition patterns, state ownership.
- `00-product-problem-statement.md` — problem context and constraints.

Before product or scope decisions:

- `02-mvp-roadmap-risks.md` — scope boundaries, milestones, risk register.
- `00-product-problem-statement.md` — user needs and privacy modes.

Before Flutter changes:

- `../skills/wanderlust-frontend/SKILL.md` — frontend design system, component patterns, and guardrails.
- `03-product-workflows-and-guardrails.md` — guardrails that the UI must enforce.
- `../skills/wanderlust-agentic-security/SKILL.md` — security practices for client-side API keys and local persistence.

## Backend Direction

- No end-user identity-provider. Backend receives `X-User-Id` header only.
- Production backend features run on Cloud Run. Backend app state is stored in
  Firestore using the anonymous `X-User-Id` device ID as the user scope.
- SQLite remains a local development and test fallback only.
- Twilio call logs use a Google Cloud database when the call service is hosted
  for public Twilio webhook/WSS callbacks, and must remain redacted.
- Google Cloud is used for external API calls, Cloud Run hosting, Firestore
  device-scoped state, and Twilio webhook/WSS callbacks.
- Local development reads API keys from `.env`; Cloud Run deployment injects secrets from Secret Manager.
- Keep external tools narrow, validated, allowlisted, and least-privileged.
- Provider checkout secrets and Stripe secret keys must remain server-side;
  Flutter must never store raw payment-card data, saved-card data, or local
  payment history for the provider-checkout flow.

## Related Files Outside `specs/`

- `../skills/wanderlust-execution-workflow/SKILL.md` — mandatory execution workflow for project development tasks.
- `../skills/wanderlust-agentic-security/SKILL.md` — mandatory security skill for agentic changes.
- `../wanderlust-backend/README.md` — backend local setup and guardrails summary.
- `../wanderlust-frontend-flutter/README.md` — Flutter frontend setup and guardrails summary.
