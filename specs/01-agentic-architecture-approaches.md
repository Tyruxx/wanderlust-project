# Agentic Architecture Approaches

## Architecture Goals

The app should use ADK 2.0 to coordinate multiple specialized agents while keeping privacy, correctness, and latency under control. The central design challenge is balancing autonomy with predictable product behavior.

The recommended architecture is a hybrid:

- Graph workflows for critical planning and verification paths.
- Ambient agents for active-mode location and itinerary-deviation events.
- Specialized agents for planning, research, verification, personalization, and notification.
- Deterministic services for permissions, location state, itinerary state, dynamic user preferences, place cache, source connectors, and notification rules.

## System Context

High-level components:

- Flutter mobile app: local preference onboarding, device-local Saved Itineraries, add itinerary flow, itinerary start/stop/complete controls, itinerary display, active suggestions, location permission handling, and local preference persistence.
- Backend API: stateless or minimally stateful agent orchestration, itinerary lifecycle validation for submitted requests, location event ingestion, source verification, and agent run orchestration. Backend agent calls receive explicit request context from the app and do not depend on end-user identity credentials.
- ADK agent service: root orchestrators and specialized agents.
- Data services: device-local traveler profile, local static preference store, itinerary-scoped dynamic preference store, local itinerary repository, backend place/evidence cache, and redacted audit/trace logs.
- External sources: Google Places API (New), Google Routes API, Google Geocoding API, Google Weather API, ADK Google Search Grounding, official venue sites, TikTok APIs only if approved, Instagram Graph API only if approved.
- Safety and evaluation layer: verification agent, output guardrails, source confidence scoring, trace review.

## Core Modes

### INACTIVE Itinerary State

INACTIVE is the saved-but-not-running itinerary state and a hard stop for agentic behavior. When an itinerary is INACTIVE, the app terminates before backend event ingestion, ADK ambient agents, planning graph workflows, active graph workflows, or recommendation services are invoked for that itinerary.

Expected behavior:

- No live location polling.
- No background geofence checks.
- No movement inference.
- No proactive nearby suggestions.
- No agent workflow of any kind.
- No ambient events, graph workflows, tool calls, or recommendation generation.
- Saved itinerary remains viewable.

Permitted data:

- Local traveler profile, saved trips, explicit preferences, explicit searches, and manual location/destination entries.

Not permitted:

- GPS collection, background location events, passive Bluetooth/Wi-Fi inference, or hidden "last known location" updates.

### ACTIVE Itinerary State

Starting an itinerary makes it ACTIVE. This is the app's active mode and should show visible state in the mobile UI.

Expected behavior:

- Collect coarse-to-precise location according to user permission.
- Detect meaningful location changes, not every GPS jitter.
- Learn dynamic trip behavior such as walking pace, dwell time, skipped stops, extended stops, and preferred routine timing.
- Trigger nearby place suggestions even without an itinerary.
- Compare current movement with active itinerary, if one exists.
- Suggest itinerary recovery when the user is late, off-route, or skips a planned stop.
- Stop collection immediately when the itinerary is stopped or marked completed.
- Stop all active services immediately when an ACTIVE itinerary is stopped or completed.

Recommended controls:

- Start itinerary.
- Stop itinerary.
- Mark as completed.
- Granularity setting: approximate area vs precise location.
- Quiet hours.
- Suggestion frequency: low, normal, high.

## Agent Roles

### Trip Intake Agent

Purpose:

- Convert loose user descriptions into structured planning constraints.

Inputs:

- User prompt, dates, destination, group size, budget, interests, constraints, prior preferences.

Outputs:

- Trip brief with normalized fields.
- Clarifying questions only when required.
- Planning assumptions.

### Local Preference Onboarding Agent

Purpose:

- Capture baseline travel preferences during first-use local preference onboarding.

Inputs:

- Local onboarding answers, preferred pace, interests, budget posture, dietary needs, accessibility constraints, day rhythm, and social discovery comfort.

Outputs:

- Structured static preference profile.
- Optional human-readable preference summary for agent context.

### Itinerary Onboarding Agent

Purpose:

- Collect itinerary-generation requirements efficiently while allowing day-level flexibility.

Inputs:

- Destination, trip length, regions to include/avoid, travel preferences, traveler context, day-level start/end locations, day-level start/end times, constraints, and must-visit places.

Outputs:

- Structured itinerary brief.
- Day grouping rules, such as day 1 to day 3 from one stay location and day 4 to day 6 from another.
- Missing-input assumptions or clarifying questions.

### Itinerary Planner Agent

Purpose:

- Build a realistic itinerary that balances user preferences, geography, time windows, pace, and diversity.

Inputs:

- Trip brief, candidate places, travel-time estimates, opening hours, budget constraints, weather constraints.

Outputs:

- Day-by-day itinerary.
- Ordered places grouped by day.
- Mandatory recommendation explanations for each place recommendation.
- Per-stop rationale.
- Backup options.
- Confidence level and unresolved assumptions.

### Place Discovery Agent

Purpose:

- Find candidate places from both conventional and unconventional sources.

Sources:

- Google Places API (New), Google Routes API, Google Geocoding API, Google Weather API, ADK Google Search Grounding, official venue pages, TikTok Research API or TikTok Display API only if approved, and Instagram Graph API only if approved.

Important constraint:

- Social platform access must be compliant. Prefer official APIs, embedded/user-shared URLs, licensed providers, or user-authorized exports. Direct scraping should be treated as a legal and reliability risk, not a default system dependency.

### Social Trend Agent

Purpose:

- Extract weak signals from social/video sources: place names, dishes, neighborhoods, queues, crowd comments, vibe, recency, creator claims.

Outputs:

- Candidate place mentions with evidence snippets.
- Source recency and popularity indicators.
- Sponsorship or affiliate suspicion flags when detectable.
- Claims requiring verification.

### Verification Agent

Purpose:

- Reduce risk of incorrect recommendations before they reach the user.

Verification checks:

- Place exists.
- Name/address match.
- Current opening hours.
- Distance from user or itinerary stop.
- Category fit.
- Price fit where available.
- Safety/accessibility constraints where available.
- Duplicate or stale social mention detection.
- Cross-source consistency.

Output confidence:

- High: authoritative source or multiple independent corroborating sources.
- Medium: one strong source plus weak supporting evidence.
- Low: social-only, stale, ambiguous, or conflicting evidence.

Policy:

- High and medium confidence can be suggested.
- Low confidence should either be hidden, shown as exploratory with clear uncertainty, or routed to user confirmation.

### Active Context Agent

Purpose:

- Interpret current context while an itinerary is ACTIVE.

Inputs:

- Current location, movement pattern, time of day, weather, open itinerary step, static preferences, and dynamic behavior profile.

Outputs:

- Context frame such as "near lunch window", "arrived in new neighborhood", "behind schedule", "near saved place", "no itinerary active".

### Dynamic Preference Agent

Purpose:

- Learn itinerary-specific behavior while an itinerary is ACTIVE so the app can adapt future recommendations to how the user actually travels.

Signals:

- Actual walking/transit pace versus planned travel time.
- Dwell time at attractions, shops, meals, and neighborhoods.
- Early/late arrivals relative to planned schedule.
- Skipped stops, extended stops, and repeated timing patterns.
- Routine signals such as preferred meal windows, rest breaks, late starts, or faster/slower exploration periods.

Outputs:

- Dynamic behavior profile for the active itinerary.
- Pace adjustment factor for remaining travel estimates.
- Suggested schedule buffer changes.
- Recovery hints for the Itinerary Recovery Agent.

Guardrail:

- Dynamic behavior preferences are inferred only while an itinerary is ACTIVE and only for itinerary adaptation. They should not be treated as permanent profile traits unless the user explicitly saves them later.

### Itinerary Lifecycle Agent

Purpose:

- Enforce itinerary status changes and single-active-itinerary behavior.

Inputs:

- Start, stop, mark completed, delete, export, or add-itinerary-preference actions from the Saved Itineraries section.

Outputs:

- Status transition: ACTIVE, INACTIVE, or COMPLETED.
- Start/stop service command for location collection and ambient workflows.
- Replacement confirmation requirement if another itinerary is already ACTIVE.

Guardrails:

- Only one itinerary can be ACTIVE at a time.
- Starting an itinerary must stop the current ACTIVE itinerary or require explicit replacement confirmation.
- Stopping or completing an itinerary must stop location collection, event ingestion, ambient workflows, active suggestions, and dynamic behavior updates.

### Itinerary Recovery Agent

Purpose:

- Suggest changes when the user does not follow the original itinerary.

Deviation examples:

- User remains far from the next stop near planned departure time.
- User skips a stop.
- User spends longer than planned at a place.
- User moves toward a different neighborhood.
- A planned venue is closed, too crowded, or weather-impacted.

Outputs:

- Keep-plan option.
- Light adjustment option.
- Reoptimized remaining day.
- Partial update option, such as modifying only the current day.
- Explanation of what changed and why.

### Notification Decision Agent

Purpose:

- Decide whether to interrupt the user.

Inputs:

- Active context, suggestion quality, urgency, user notification preferences, recent notification history, and dynamic behavior profile.

Outputs:

- Notify now, batch silently, show in app only, or suppress.

Guardrail:

- Do not notify just because a place is nearby. Notify only when the suggestion is timely, relevant, and not repetitive.

### Booking And Commerce Agent

Purpose:

- Support book, buy, and directions CTAs when applicable.

Outputs:

- Agent-assisted booking option.
- Availability search and booking-flow preparation.
- Agent-assisted booking call flow, when applicable.
- Stripe payment handoff, when applicable.
- Directions handoff.

Guardrail:

- The agent may search availability and prepare a booking flow, including a phone-call booking attempt where appropriate, but must not execute booking, payment, or a booking call without explicit user confirmation.
- The confirmation prompt must show the booking target, date/time, party size or quantity, price when known, Stripe payment details when applicable, cancellation terms when known, and uncertainty.
- After any agent-assisted booking call, the agent must report the result to the user.

## Recommended ADK 2.0 Pattern

Use graph workflows for the main planning and verification process because ADK 2.0 graph workflows support explicit routes between agents, tools, and deterministic code. This is useful where travel quality depends on ordered steps:

1. Parse request.
2. Read latest static and dynamic preference versions.
3. Discover candidates.
4. Verify facts.
5. Learn or read dynamic behavior profile when an itinerary is ACTIVE.
6. Plan or recover route.
7. Score itinerary.
8. Generate user-facing explanation.

Use ambient agents for ACTIVE itineraries because location changes and itinerary deviations are event-like. ADK ambient agents can process external events through run or trigger endpoints, which fits events such as:

- Location changed meaningfully.
- User entered/leaves itinerary area.
- Scheduled stop start time is approaching.
- User arrives at an itinerary place.
- User pace, dwell time, or routine pattern differs from the original itinerary assumption.
- User preference or saved itinerary preference changes while an itinerary is ACTIVE.
- External source reports venue closure or weather alert.

Use custom tools for source access, maps, travel time, social connectors, place cache reads, and verification APIs. Keep tools deterministic and narrow.

## External APIs And MCP Adapters

Approved external APIs and tool adapters:

- Google Places API (New): place search, nearby search, place details, reviews/ratings, opening hours, and photos.
- Google Routes API: travel time, route feasibility, route-aware place selection, and remaining-day recovery.
- Google Geocoding API: address normalization, coordinate lookup, and ambiguous place disambiguation.
- Google Weather API: weather-aware itinerary planning and outdoor activity adjustment.
- ADK Google Search Grounding: official venue pages, recent closures, factual cross-checking, and web grounding.
- Device-native location APIs: iOS Core Location and Android Fused Location Provider for ACTIVE itineraries only.
- TikTok Research API or TikTok Display API: social discovery signals only when approved access, scopes, and terms allow.
- Instagram Graph API: social discovery signals only for eligible public/business/creator or user-authorized content when approved access, scopes, and terms allow.
- Official venue websites: authoritative fallback for hours, closures, policies, and event details.

Agents should access these dependencies through ADK custom tools or internal MCP adapters that enforce authentication, rate limits, logging, allowlists, and guardrails. Agents must not call arbitrary third-party MCP servers directly.

Architecture diagram:

- PlantUML source: [agentic-architecture.puml](/Users/alan/Documents/Project%20Trip/specs/agentic-architecture.puml)

## Architecture Approach A: Single Root Orchestrator With Specialized Subagents

Description:

- One root trip agent delegates to specialized subagents.
- The root owns user conversation and final response.
- Subagents handle discovery, verification, planning, and recovery.

Pros:

- Simple mental model.
- Fast to prototype.
- Good fit for MVP.
- Easier UX because one agent personality speaks to the user.

Cons:

- Root agent can become overloaded.
- Harder to enforce strict workflows unless paired with graph routing.
- Risk of prompt sprawl.

Recommended use:

- MVP and early beta.

## Architecture Approach B: Graph-First Workflow Agents

Description:

- Critical user journeys are explicit ADK graph workflows.
- Each node is an agent, tool, or deterministic function.
- Routing depends on structured outputs and confidence scores.

Pros:

- More predictable.
- Easier to evaluate and trace.
- Better for verification and safety.
- Clear fallback paths when evidence is weak.

Cons:

- More design upfront.
- Less flexible for open-ended conversational exploration.
- Requires careful schema design.

Recommended use:

- Planning generation, recommendation verification, itinerary recovery.

## Architecture Approach C: Event-Driven Ambient Active Mode

Description:

- The mobile app and backend emit events.
- ADK ambient agents process events and produce suggestions, itinerary updates, or silent no-op decisions.

Pros:

- Natural fit for started itineraries.
- Scales independently from chat planning.
- Clear control over when the agent wakes up.

Cons:

- Requires strong notification throttling.
- Needs robust state management to avoid repeated suggestions.
- More privacy-sensitive.

Recommended use:

- Started-itinerary services after MVP planning flow is stable.

## Recommended MVP Architecture

Use a combined version of A, B, and C:

- Conversational root agent for user-facing planning and post-onboarding itinerary chat.
- Local preference onboarding and itinerary onboarding agents for preference and trip brief capture.
- Graph workflow for itinerary planning and verification.
- Itinerary lifecycle service to enforce ACTIVE, INACTIVE, COMPLETED status and one ACTIVE itinerary.
- Ambient event handler for active-mode suggestions and itinerary recovery.
- Dynamic preference agent that learns behavior during the active itinerary and feeds pace-aware recovery.
- Preference versioning so changed or reset preferences affect active services immediately.
- Deterministic permission service that gates all active-mode behavior.
- Inactive-mode hard stop before backend events, ADK workflows, or tool calls.

The root agent should never directly bypass verification for user-facing place suggestions.

## Data Model Concepts

Trip:

- Destination, dates, travelers, constraints, preferences, saved itinerary, status, active status, and repository metadata.

Itinerary status:

- ACTIVE, INACTIVE, or COMPLETED. Only one itinerary can be ACTIVE per user.

Itinerary stop:

- Place ID, name, coordinates, scheduled window, expected duration, booking requirement, payment/directions availability, confidence, alternatives.

Itinerary day:

- Day number/date, start location, end location, start time, end time, ordered stops, travel assumptions, and day-level constraints.

Recommendation:

- Place or activity reference, what to do, mandatory explanation/reasoning, source summary, confidence, expanded/collapsed UI state, and applicable CTAs.

Static preference profile:

- Device-local preferences, pace, interests, budget posture, dietary/accessibility constraints, day rhythm, and social discovery comfort.

Place evidence:

- Source type, source URL or provider ID, timestamp, extracted claim, verification status, confidence.

User context:

- Itinerary lifecycle state, current approximate/precise location while ACTIVE, movement summary, static preference memory, and dynamic behavior profile.

Dynamic behavior profile:

- Active itinerary ID, inferred pace factor, typical dwell time by stop type, meal/rest timing signals, skipped/extended stop patterns, confidence, and last updated timestamp.

Preference version:

- Version ID, updated timestamp, changed fields, and propagation state for active workflows.

Agent trace:

- Agent run ID, input event, tools called, source evidence used, behavior signals used, confidence score, final decision, notification decision.

## Trust And Accuracy Design

Every user-facing recommendation should include:

- Why this is relevant now.
- Mandatory explanation/reasoning.
- Distance or travel time.
- Whether it is open now, if known.
- Confidence level.
- Source basis such as "verified with Google place data and official site" or "popular on social, not fully verified."

Do not present uncertain claims as facts. For example:

- Preferred: "This place is trending for late-night noodles, but current wait time is unverified."
- Avoid: "This is the best late-night noodle spot."

## Privacy Design

Hard rules:

- Starting an itinerary must be explicit.
- Stopping or completing an itinerary must stop location collection.
- Stopping or completing an itinerary must stop active services immediately.
- Location should be stored at the lowest precision needed.
- Retention should be short for raw location events.
- Dynamic behavior preferences should not require storing full location trails.
- Dynamic behavior preferences should default to itinerary-scoped memory, not permanent profile memory.
- Static and dynamic preferences must be stored as structured data. Markdown summaries can be generated for agent context but must not be the source of truth.
- Resetting onboarding preferences must erase locally stored preferences and saved itinerary preference patterns, return the user to local preference onboarding, refresh the local preference version, and must not delete saved itineraries.
- Users should be able to delete trip and location history.

Recommended retention:

- Raw location events: 24-72 hours during active trip, unless user saves them explicitly.
- Derived visit events: retained only as itinerary state or itinerary-scoped dynamic behavior preferences with user control.
- Agent traces: redact precise coordinates where possible.

## Failure Modes

- Agent suggests a closed venue.
- Social source mentions the wrong branch of a place.
- User walks away from itinerary but does not want replanning.
- User tries to start a second itinerary while another is ACTIVE.
- User changes preferences while active workflows are running.
- Location jitter causes false deviation.
- Suggestion is correct but socially inappropriate, unsafe, or inaccessible.
- Platform scraping breaks or violates terms.
- Approved social API access is unavailable or too limited.

Mitigations:

- Verification before suggestion.
- Confidence thresholds.
- Official/place data as authority for facts.
- Notification throttle.
- Status transition guardrails.
- Preference version checks before new active recommendations.
- Source connector governance.
- Evaluation set with adversarial and stale-data cases.
