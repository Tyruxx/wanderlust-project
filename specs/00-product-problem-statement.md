# Agentic Trip Planner - Product Problem Statement

## Working Summary

Build a lightweight, agentic trip planner that helps travelers create, adjust, and enrich itineraries using Google's Agent Development Kit (ADK) 2.0. The app has two privacy modes:

- INACTIVE itinerary: saved but not running; all agentic services disabled; no workflow, no location collection, and no suggestions.
- ACTIVE itinerary: started itinerary; starting an itinerary is the app's active mode, enabling opt-in live location awareness, location-change detection, context-aware suggestions, and itinerary recovery.

The core product promise is: "Plan the trip with an agent, then let the agent adapt with you while you travel."

The current frontend implementation target is **Flutter**. Earlier prototype or design references should be interpreted through the Flutter app structure.

## Problem

Travel planning is rarely linear. People describe what they want loosely, discover new places from social media, change their minds mid-trip, get delayed, miss planned stops, or end up in a neighborhood with no idea what to do next. Traditional itinerary apps assume the plan is fixed. Chat-style planners can generate a plan, but they usually stop being useful after the itinerary is created.

This creates several traveler problems:

- Plans do not react to real-world deviation.
- Recommendations often feel generic because they ignore where the traveler is right now.
- Social discovery sources like TikTok and Instagram influence travel decisions, but are rarely incorporated into structured planning.
- User trust is fragile because AI-generated travel details can be stale, hallucinated, closed, unsafe, or logistically impossible.
- Always-on location products can feel invasive unless consent boundaries are crisp and visible.

## Target Users

Primary users:

- Independent travelers who want flexible itineraries.
- Small groups that need practical day-by-day plans.
- Travelers who prefer discovery from social/video platforms, not only official tourism guides.
- Users who want help while moving around a destination, not only before the trip.

Secondary users:

- Frequent weekend travelers.
- Digital nomads exploring a new city.
- Families who need schedule-aware alternatives when a plan slips.

## Jobs To Be Done

- When I describe a trip, I want the app to convert messy preferences into a realistic itinerary so I can start quickly.
- When I first use the app, I want local preference onboarding to capture my travel preferences so first itineraries already feel personalized.
- When I create an itinerary, I want a guided onboarding flow that captures trip length, places/regions, daily start/end locations, and daily start/end times without making setup tedious.
- When I fall behind, skip an activity, or go somewhere else, I want the app to adjust the plan without making me re-plan the whole day.
- When my real travel pace differs from the original plan, I want the app to learn my behavior during the itinerary and adapt future suggestions accordingly.
- When I start an itinerary somewhere unfamiliar, I want nearby suggestions that fit my current context, not a generic list.
- When a recommendation comes from social media or a less conventional source, I want confidence that the app verified it before suggesting it.
- When I stop or complete an itinerary, I want confidence that location and movement data are not being collected.
- When I manage saved itineraries, I want to start, stop, mark completed, delete, export to PDF, or save the latest itinerary preference pattern into my preferences.

## Product Principles

- Consent first: starting an itinerary is explicit, reversible, and visible.
- Agentic, not chaotic: agents may investigate, compare, and reason, but must follow bounded workflows for accuracy, safety, and privacy.
- Freshness matters: place availability, opening hours, distance, price, and transit constraints should be checked close to recommendation time.
- Explain confidence: the app should show why it suggests a change, what evidence supports it, and what uncertainty remains.
- Lightweight by default: the MVP should prove the agentic loop before adding heavy booking, payments, or social features.

## In Scope

- Natural language trip intake: destination, dates, budget, pace, interests, constraints, group profile, dietary needs, accessibility needs.
- Local preference onboarding for baseline travel preferences.
- Itinerary onboarding for duration, coverage area, day-level start/end locations, and day-level start/end times.
- Agent-generated itinerary with day plans, neighborhoods, travel time assumptions, meal windows, and fallback options.
- Combined Itinerary page for saved trips and adding new itineraries, with start, stop, mark completed, delete, export to PDF, and add-itinerary-preference actions.
- Itinerary lifecycle statuses: ACTIVE, INACTIVE, COMPLETED.
- Single-active-itinerary enforcement.
- Agent chat after onboarding for itinerary modification and travel questions.
- Started-itinerary location-change detection.
- Nearby place suggestions while an itinerary is ACTIVE.
- Itinerary deviation detection and proactive replanning suggestions.
- Dynamic user preference learning during active itineraries, including pace, dwell time, routine timing, and repeated behavior signals used to improve itinerary recovery.
- Individual add/delete/reset controls for saved itinerary preference patterns and onboarding preferences, with immediate compliance by active services. Reset erases locally stored preferences and saved itinerary preference patterns, returns the user to local preference onboarding, refreshes the local preference version, and does not delete saved itineraries.
- Source gathering through approved APIs and compliant sources: Google Places API (New), Google Routes API, Google Geocoding API, Google Weather API, ADK Google Search Grounding, official venue websites, TikTok APIs only if approved, and Instagram Graph API only if approved.
- Verification agent that cross-checks place facts and flags low-confidence recommendations.

## Out of Scope For MVP

- Fully autonomous flight, hotel, ticket, or restaurant booking without explicit user confirmation.
- Payment processing outside Stripe.
- Fully automated reservation calls or messages.
- Scraping that violates platform terms or privacy expectations.
- Social posting or influencer-style feed features.
- Real-time safety/emergency response.
- Offline-first navigation.

## Success Metrics

Planning metrics:

- Percentage of trip descriptions that produce a complete itinerary without follow-up.
- Itinerary onboarding completion rate.
- User acceptance rate of initial itinerary suggestions.
- Average number of user edits needed before saving a plan.

Started-itinerary metrics:

- Itinerary start rate.
- Start/stop itinerary success rate with only one ACTIVE itinerary at a time.
- User-marked completion rate.
- Suggestion click-through rate.
- Accepted replanning suggestion rate after detected deviation.
- Accuracy of pace-aware itinerary adjustments, measured by reduced future late/early deviations during an active trip.

Trust and quality metrics:

- Verified recommendation coverage: percentage of suggestions with at least two corroborating sources or one authoritative source.
- Hallucinated place rate.
- Percentage of suggestions with clear confidence and freshness metadata.

Privacy metrics:

- Active-to-inactive switch completion rate.
- Number of privacy complaints or support tickets.
- Location data retention compliance rate.

## Key Product Risks

- Recommendations from social platforms may be trendy but inaccurate, outdated, sponsored, or inaccessible.
- Location tracking can undermine trust if the mode boundary is not clear.
- Replanning can become annoying if the app over-notifies users after normal wandering.
- Agent workflows can be slow or expensive if every suggestion triggers deep research.
- Place data licensing and platform terms may limit use of TikTok APIs or Instagram Graph API for social discovery.

## Product Positioning

This app is not just a chatbot that writes itineraries. It is an agentic travel companion with bounded autonomy:

- Before the trip, it plans.
- During the trip, it observes only with consent.
- When reality changes, it proposes practical adjustments.
- Before recommending something, it verifies facts and communicates uncertainty.

## ADK 2.0 References

Planning assumptions in these specs are based on Google's current ADK 2.0 documentation:

- ADK 2.0 supports production agents across Python, TypeScript, Go, Java, and Kotlin: https://adk.dev/
- Graph workflows support deterministic routing mixed with LLM reasoning: https://adk.dev/graphs/
- Ambient agents support event-driven runs from external triggers: https://adk.dev/runtime/ambient-agents/
- ADK tools allow agents to call structured functions, APIs, databases, search, and external systems: https://adk.dev/tools-custom/
- ADK safety guidance recommends auth boundaries, guardrails, evaluation, tracing, and network controls: https://adk.dev/safety/
