# MVP Scope, Roadmap, And Risks

## MVP Thesis

The MVP should prove that an agentic travel planner can do two things better than a normal itinerary app:

1. Turn loose trip intent into a practical, verified itinerary.
2. Adapt suggestions during a started itinerary based on where the user actually is.

The product should avoid booking, payments, and broad social automation until trust, verification, and privacy behaviors are working.
INACTIVE itinerary state is a hard stop: all agentic services are disabled, with no workflow, no location collection, and no suggestions.

## MVP User Journeys

### Journey 0: Complete Local Preference Onboarding

User opens the app on a device for the first time.

Expected flow:

1. Local Preference Onboarding Agent asks for baseline preferences, pace, interests, budget posture, day rhythm, dietary needs, accessibility needs, and social discovery comfort.
2. App stores the answers as structured device-local static preferences.
3. Agent generates an optional preference summary for future planning context.

MVP acceptance criteria:

- Local preference onboarding is required before the first itinerary generation.
- User can edit, delete, or reset preferences after onboarding.
- Resetting preferences erases locally stored preferences and saved itinerary preference patterns, returns the user to local preference onboarding, refreshes the local preference version, and does not delete saved itineraries.
- Preference changes apply immediately to future agent recommendations, including active workflows.

### Journey 1: Plan A Trip From A Description

User says:

"I'm going to Tokyo for 4 days. I like ramen, photography, quiet neighborhoods, vintage shopping, and I don't want to wake up too early."

Expected flow:

1. Itinerary Onboarding Agent captures destination, trip length, regions, daily start/end locations, daily start/end times, travel preferences, and constraints.
2. Trip Intake Agent extracts structured preferences and itinerary requirements.
3. Place Discovery Agent collects candidate neighborhoods, restaurants, shops, and activities.
4. Verification Agent checks existence, location, opening hours, and source quality.
5. Itinerary Planner Agent builds a paced day-by-day plan.
6. User sees itinerary with rationale, alternatives, confidence, and CTAs.

MVP acceptance criteria:

- Itinerary includes daily time windows, neighborhoods, meal suggestions, travel assumptions, and fallback options.
- Itinerary supports grouped day rules, such as day 1 to day 3 using one start/end place and day 4 to day 6 using another.
- Every recommended place has verification status.
- Every recommendation has a brief explanation/reasoning that can be expanded or collapsed.
- User can edit preferences and regenerate.
- User can chat with the agent after onboarding to modify the itinerary or ask questions.

### Journey 1A: Manage Itineraries In The Itinerary Page

User opens the Itinerary page.

Expected flow:

1. App lists saved itineraries in the Saved Itineraries section with status: ACTIVE, INACTIVE, or COMPLETED.
2. Each itinerary exposes start, stop, mark completed, delete, export to PDF, add itinerary preference into preferences, open details, and chat actions.
3. Starting an itinerary enforces that only one itinerary can be ACTIVE.
4. Stopping an itinerary stops location and active agent services.

MVP acceptance criteria:

- Only one itinerary can be ACTIVE at a time.
- Start/stop can happen at any time.
- Stop immediately stops location collection, backend event ingestion, ambient workflows, active suggestions, and dynamic behavior updates.
- Mark completed is user-initiated and immediately stops active services.
- Export to PDF is available from the repository.
- Adding the itinerary preference pattern into preferences updates preference state immediately.

### Journey 2: Started Itinerary Suggestions

User starts an itinerary while walking around Singapore.

Expected flow:

1. App receives location permission.
2. Location change event is sent only after meaningful movement.
3. Active Context Agent identifies current context.
4. Place Discovery Agent finds nearby options.
5. Verification Agent filters candidates.
6. Notification Decision Agent decides whether to show a suggestion.

MVP acceptance criteria:

- App suggests nearby food, attractions, cafes, viewpoints, or shops based on time and preference.
- App does not require an itinerary to be useful.

### Journey 3: User Deviates From Started Itinerary

User is scheduled to visit a museum at 2:00 PM but stays at lunch until 2:30 PM and moves away from the museum.

Expected flow:

1. The started itinerary detects likely deviation.
2. Dynamic Preference Agent compares actual pace and dwell time against the original itinerary assumptions.
3. Itinerary Recovery Agent evaluates remaining day using the dynamic behavior profile.
4. Agent suggests: keep original plan, skip museum and move next stop, add buffer, or replace with nearby alternative.
5. User chooses one option.

MVP acceptance criteria:

- App does not nag immediately.
- Suggestion explains the reason: "You are now 35 minutes from the museum and it closes at 5:00 PM."
- Suggestion accounts for learned behavior, such as slower walking pace or longer meal dwell time.
- User can apply the updated itinerary or chat with the agent to modify it, including changing only the current day.
- User can ignore and continue.

### Journey 4: Arrival Is Recognized In The UI

User starts an itinerary and arrives at a scheduled place.

Expected flow:

1. The ACTIVE itinerary detects arrival using location, dwell time, and route context.
2. App highlights the matched place in the itinerary UI.
3. Active Context Agent updates the active context for the next step.

MVP acceptance criteria:

- Arrival highlighting tolerates GPS noise.
- Arrival detection does not run for INACTIVE or COMPLETED itineraries.
- The highlighted stop changes only when confidence is sufficient.

## MVP Functional Scope

Planning:

- Local preference onboarding.
- Itinerary onboarding.
- Natural-language trip intake.
- Structured trip brief.
- Generated itinerary.
- Combined Itinerary page with Saved Itineraries section.
- Itinerary status: ACTIVE, INACTIVE, COMPLETED.
- Start, stop, mark completed, delete, export to PDF, and add-latest-trip-style-to-preferences actions.
- Single-active-itinerary enforcement.
- Alternatives per day.
- Basic static preference memory.
- Dynamic behavior preference learning during active itineraries.
- Agent chat for itinerary changes and questions.
- Verification-first recommendation pipeline.

Started itinerary services:

- Itinerary start/stop controls.
- User-marked completion control.
- Location event ingestion.
- Meaningful movement detection.
- Arrival detection and active-stop highlighting.
- Nearby suggestions.
- Itinerary deviation detection.
- Pace and dwell-time behavior detection.
- Replanning suggestions.
- Notification throttling.

Sources:

- Google Places API (New).
- Google Routes API.
- Google Geocoding API.
- Google Weather API.
- ADK Google Search Grounding.
- Official venue websites.
- TikTok Research API or TikTok Display API only if approved.
- Instagram Graph API only if approved.
- Limited social trend ingestion through compliant approved sources only.

Trust:

- Confidence labels.
- Source summaries.
- Mandatory explanation/reasoning for every recommendation.
- Explicit confirmation gates for agent-assisted booking, Stripe payment, and booking calls.
- Agent traces for internal review.

## Non-Functional Requirements

Privacy:

- INACTIVE itinerary state must collect no live location data and must not invoke backend event ingestion, ADK workflows, tool calls, or suggestions.
- INACTIVE and COMPLETED itineraries must not run active services.
- ACTIVE itinerary state must visibly indicate collection.
- Raw location retention should be limited.
- Preference changes must be versioned and applied to active services before new recommendations are generated.

Latency:

- Initial itinerary target: under 30 seconds for standard plans.
- Active nearby suggestion target: under 5 seconds using cached candidates.
- Deep social/source research can run asynchronously and enrich later.

Reliability:

- If social sources fail, fallback to verified conventional sources.
- If verification is inconclusive, recommendation should be suppressed or marked exploratory.
- If location is unavailable, started-itinerary services should degrade to manual neighborhood selection.
- If dynamic behavior confidence is low, recovery should fall back to original itinerary assumptions.
- If another itinerary is already ACTIVE, starting a different itinerary should require stopping or replacing the current active itinerary.

Cost:

- Cache place candidates and evidence.
- Use cheaper/faster models for classification, safety checks, and notification decisions.
- Reserve frontier models for complex planning, conflict resolution, and nuanced itinerary recovery.

## Agent Evaluation Plan

Evaluation should start before launch. Suggested test suites:

- Planning quality: itineraries match stated preferences, constraints, and pace.
- Geographic coherence: stops are grouped sensibly and travel time is plausible.
- Freshness: venues are open and still exist.
- Social claim verification: trending claims are cross-checked before being treated as fact.
- Deviation recovery: suggestions improve the remaining day without overcorrecting.
- Dynamic behavior adaptation: recovery suggestions account for learned pace, dwell time, and routine timing.
- Lifecycle compliance: active-only behaviors never run for INACTIVE or COMPLETED itineraries.
- Notification discipline: app suppresses low-value interruptions.
- Itinerary lifecycle: only one ACTIVE itinerary, and stop/completion halts all active services.
- Preference propagation: changed, deleted, or reset preferences affect active recommendations immediately.

Useful evaluation scenarios:

- Ambiguous destination names.
- Multiple branches of the same restaurant.
- Closed or temporarily relocated venues.
- Viral but low-quality tourist traps.
- Sponsored social content.
- User with dietary/accessibility constraints.
- Bad weather during outdoor-heavy itinerary.
- User intentionally wandering off-plan.
- User consistently slower or faster than original itinerary assumptions.
- User repeatedly takes longer meals or rest breaks than planned.
- Itinerary stopped while a trip is saved.
- User starts a second itinerary while one is ACTIVE.
- User changes or resets preferences while an itinerary is ACTIVE.
- User arrives near, but not exactly at, an itinerary stop.

## Key Product Decisions

### Decision 1: Social Sources Are Discovery Signals, Not Truth Sources

TikTok, Instagram, and similar sources should help discover candidate places and vibes. They should not be final authorities for factual claims like hours, address, price, safety, or availability.

### Decision 2: Verification Is A Required Gate

The system should not show normal recommendations until the Verification Agent has checked minimum facts. Low-confidence suggestions can exist only in an exploratory UI treatment.

### Decision 3: Starting An Itinerary Is The Active Mode

Starting an itinerary is the app's active mode. There is no separate active-mode state independent from itinerary lifecycle.

### Decision 4: Replanning Suggestions Should Be User-Confirmed

The app can proactively suggest itinerary changes, but it should not silently rewrite the user's plan unless the user opts into auto-adjustment later.

### Decision 5: Dynamic Preferences Are Itinerary-Scoped By Default

The app can infer behavior such as pace, dwell time, and routine timing during a started itinerary, but these preferences should be used for the active itinerary first. They should become permanent profile preferences only through a later explicit save experience.

### Decision 6: Itinerary Page Is The Saved Trip Home

The bottom navigation destination should be called Itinerary. Inside it, the saved itinerary list section should be called Saved Itineraries. It is the main place to start, stop, mark completed, delete, export, and convert an itinerary preference pattern into preferences.

### Decision 7: Recommendation Reasoning Is Mandatory

Every place recommendation must include a brief explanation, description, or reasoning. The UI may collapse it by default, but the content must exist.

## Architecture Milestones

### Milestone 1: Planning Foundation

- Local preference onboarding.
- Itinerary onboarding.
- Trip intake schema.
- Static preference schema.
- Place discovery connector set.
- Verification scoring.
- Itinerary planning graph workflow.
- Recommendation explanation contract.
- Basic itinerary UI contract.

### Milestone 2: Active Mode Foundation

- Mode permission model.
- Itinerary lifecycle status model.
- Single-active-itinerary enforcement.
- Location event ingestion.
- Meaningful movement detection.
- Arrival detection and UI highlighting.
- Dynamic behavior preference extraction.
- Nearby suggestion workflow.
- Notification decision workflow.

### Milestone 3: Itinerary Recovery

- Deviation detection.
- Pace-aware and dwell-time-aware recovery logic.
- Replanning workflow.
- User confirmation states.
- User-confirmed itinerary updates.
- Partial itinerary recovery, such as modifying only the current day.

### Milestone 3A: Repository And Exports

- Combined Flutter Itinerary page with a Saved Itineraries section.
- Add itinerary flow from the Itinerary page.
- Start, stop, mark completed, delete, export to PDF, and add-itinerary-preference actions.
- Preference reset/delete/add operations with immediate propagation.

### Milestone 4: Social Trend Expansion

- TikTok Research API or TikTok Display API integration where approved.
- Instagram Graph API integration where approved.
- Licensed or approved API-based social trend providers.
- Trend-to-place entity resolution.
- Sponsorship/staleness heuristics.

### Milestone 5: Quality And Safety Hardening

- Regression evaluation suite.
- Trace review dashboard.
- Source reliability monitoring.
- Privacy audit.
- Red-team tests for prompt injection through scraped/social content.

## Open Questions

- Which first market or destination should be used for MVP testing?
- Should started itineraries use approximate location by default and precise location only on demand?
- How should the app display uncertain social discoveries without reducing trust?
- What level of source citation is acceptable in the consumer UI?
- Which backend ADK runtime should pair with the Flutter frontend first: Python ADK or TypeScript ADK?
- What licensed providers, if any, are available for social/video trend discovery?
- Should group trips share one ACTIVE itinerary context or keep each traveler's location separate?

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Unapproved social scraping violates platform terms | Legal and operational risk | Use approved TikTok APIs, Instagram Graph API, licensed providers, or remove social ingestion from MVP |
| AI suggests incorrect place details | Trust erosion | Verification gate, source confidence, regression tests |
| Started itinerary services feel invasive | User churn | Explicit start/stop, visible state, quick off switch, short retention |
| Dynamic preferences feel too personal | Trust erosion | Scope behavior memory to the active itinerary by default and avoid full trail storage |
| Second itinerary starts accidentally | Confusing active state and privacy risk | Enforce one ACTIVE itinerary and require explicit replacement |
| Preference changes do not propagate | Irrelevant active recommendations | Version preferences and re-read before new suggestions |
| Agent books or pays without enough trust | Financial or user trust risk | Require explicit confirmation with booking target, price, terms, uncertainty, and Stripe details where applicable |
| Over-notification | Annoyance | Notification Decision Agent, cooldowns, relevance thresholds |
| High latency from deep research | Poor UX | Cache candidates, async enrichment, split quick suggestions from deep planning |
| Prompt injection from web/social content | Safety risk | Treat external content as untrusted, use tool guardrails, callbacks, output validation |
| Ambiguous place matching | Wrong recommendations | Entity resolution with address, coordinates, aliases, and source corroboration |

## Launch Recommendation

Launch the first private beta in one city with strong place data coverage and active food/culture discovery behavior. A constrained geography will make verification, evaluation, and source quality easier to control while proving the agentic loop.

Recommended first beta feature set:

- Complete local preference onboarding.
- Add an itinerary from the Itinerary page.
- Save itinerary.
- Manage trips in the Saved Itineraries section of the Itinerary page.
- Start/stop one active itinerary.
- Mark itinerary completed.
- Export trip to PDF.
- Get nearby suggestions.
- Receive itinerary recovery suggestions.

Do not launch broad social scraping as a core dependency. Treat social discovery as an enrichment layer after the verified planning and active-mode loop is reliable.
