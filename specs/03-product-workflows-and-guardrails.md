# Product Workflows And Guardrails

## Purpose

This document captures product workflow requirements and development guardrails for the agentic trip planner. Treat these as source-of-truth constraints when designing screens, APIs, agents, data models, and background services.

## Local Preference Onboarding

Every device-local traveler profile must complete preference onboarding before generating the first itinerary.

Onboarding should capture baseline travel preferences:

- Preferred pace: relaxed, balanced, packed, or user-described.
- Interests: food, nature, museums, shopping, nightlife, photography, family-friendly, hidden gems, luxury, budget, local culture, and similar categories.
- Budget posture.
- Food and dietary preferences.
- Accessibility or mobility constraints.
- Typical day rhythm: early start, late start, afternoon break, late-night activity, or flexible.
- Social discovery comfort: whether the user wants recommendations influenced by TikTok/Instagram-style trend signals when compliant sources are available.

Guardrails:

- Onboarding preferences are editable after first-use setup.
- Onboarding should be efficient; do not make users answer every possible preference before they can create a trip.
- These are baseline static preferences. Active itinerary behavior can temporarily override them through dynamic behavior preferences.

## Preference Management

The user can manage saved itinerary preference patterns and onboarding preferences individually.

Required actions:

- Add the most updated itinerary preference pattern into preferences from a generated itinerary.
- Delete an individual saved itinerary preference pattern.
- Reset all saved itinerary preference patterns/preferences to defaults.
- Modify preference values manually.

Immediate compliance rule:

- When preferences are added, deleted, modified, or reset, all services must comply immediately, including active itinerary services.
- Active workflows should re-read the latest preference version before making new suggestions or recovery proposals.
- Already-shown suggestions do not need to be rewritten, but future suggestions must use the latest preference state.
- Resetting all onboarding preferences must erase locally stored preferences and saved itinerary preference patterns, return the user to local preference onboarding, and refresh the local preference version.
- Resetting preferences must not delete existing saved itinerary data.

Storage rule:

- Preferences should be stored as structured data for agents and services.
- A Markdown or natural-language summary may be generated for agent context, but it must not be the sole source of truth.

## Itinerary Onboarding

The itinerary generation flow should ask for inputs in an intuitive order:

1. A required trip name, used unchanged as the saved itinerary card title and PDF title.
   - Trip names are trimmed, limited to 80 characters, and do not need to be unique.
2. Destination or broad place to cover.
   - Region fields should support Google Maps-backed autocomplete suggestions.
   - If the user does not select a suggestion, the typed region remains valid.
3. Trip length in days.
4. Regions/neighborhoods/areas to include or avoid.
5. Traveler count and traveler type, if relevant.
6. Trip style and interests, defaulting from locally stored preferences.
7. Radius guidance around the chosen region. This is a flexible proximity guide for where activities may be placed, not a hard exclusion boundary.
8. Preferred transport modes, with multi-select support.
9. Optional day-level start and end locations, also supporting Google Maps-backed autocomplete while preserving typed freeform values.
   - Selecting an autocomplete result must focus the place-picker map on that exact result.
   - When omitted, the planner chooses suitable day boundaries from the trip brief and verified place evidence.
10. Day-level start and end times.
11. Constraints: budget, dietary needs, accessibility, must-visit places, rest days, booking requirements.

Flexibility rule:

- Users should be able to define the same start/end place or time for all days.
- Users should also be able to group day ranges, such as day 1 to day 3 from Hotel A, and day 4 to day 6 from Hotel B.
- Users should be able to override individual days without duplicating work.

Efficiency rule:

- The default flow should be fast for simple trips.
- Advanced day-by-day customization should be available but should not block the basic itinerary generation path.

## Itinerary Page And Saved Itineraries

The Flutter frontend uses a bottom navigation destination called **Itinerary**. This page combines itinerary creation and repository management.

The Itinerary page must expose:

- Add itinerary.
- A saved itinerary list section called **Saved Itineraries**.

The add itinerary action routes to a separate Add Itinerary page.

Each itinerary in Saved Itineraries must expose:

- Start itinerary.
- Stop itinerary.
- Mark as completed.
- Delete itinerary.
- Open a device-local PDF preview and explicitly download/share the PDF through the platform save sheet.
- Add the preference pattern of this trip into user preferences.
- Open itinerary details by tapping the itinerary card.
- Chat with the itinerary agent from the itinerary detail page.

Lifecycle statuses:

- ACTIVE: itinerary is currently started and running. Starting an itinerary is the app's active mode; location and active services may run according to permission.
- INACTIVE: itinerary is saved but not running; no workflow, location, ambient agents, active suggestions, or active services run for that itinerary.
- COMPLETED: user has marked the itinerary as completed; location and active services are stopped, and the itinerary remains available for review/export/style extraction.

Single-active rule:

- Only one itinerary can be ACTIVE at a time.
- Starting an itinerary must stop any currently ACTIVE itinerary first or require the user to confirm replacement.
- Stopping an itinerary must immediately stop location collection, active event ingestion, ambient agent workflows, and active suggestions for that itinerary.
- Marking an itinerary as completed must be user-initiated and must immediately stop active services.

## Itinerary Detail Requirements

An itinerary is a list of places grouped by day.

Each day should show:

- Day date or day number.
- Start location and end location.
- Start time and end time.
- Ordered places to go.
- Travel time assumptions between places.
- Optional backup or flexible alternatives.

Each place should show:

- Place name.
- Time window or suggested visit order.
- What to do there.
- Recommendations attached to that place, such as a restaurant, viewpoint, activity, shop, or booking opportunity.
- Mandatory brief explanation, description, or reasoning for every recommendation.
- Expand/collapse behavior for recommendation reasoning.
- Confidence and source summary when relevant.

Activity specificity rule:

- Every itinerary activity must name a specific, evidence-backed, map-searchable venue, landmark, trail, tour, market, restaurant, or activity provider.
- Generic placeholders such as `Lunch at <city>`, `City Center`, `local restaurant`, `museum visit`, `shopping area`, or `free time` are not valid activity places.
- Food activities should use a suitable label such as Breakfast, Brunch, Lunch, Dinner, Cafe, Restaurant, Dessert, Drinks, or Food market rather than labeling every food stop as Breakfast.

Between ordered places, the itinerary detail UI should show route information
when available:

- Duration.
- Selected or preferred travel mode.
- Distinct route section between the two activity cards.
- Tapping the route section highlights that route on the map.

Map behavior:

- Routes should be computed using the user's preferred transport modes when available.
- When multiple preferred modes are selected, every mode should be evaluated per route gap and the shortest valid Google Routes result selected for that gap. Selection order breaks duration ties.
- Tapping an activity card should focus the map on that activity's location when coordinates are available.
- Device location, active arrival state, ambient active services, and dynamic behavior updates are ACTIVE-only.

Supported CTAs, when applicable:

- Show directions.
- Actions.

The **Actions** CTA opens an activity-scoped action hub with:

- **Call the Venue**.
- **Book or Buy Packages**.
- **Ask Agent Anything**.

Payment and booking guardrail:

- **Call the Venue** may start a whole-page conversational flow for agent-assisted booking calls or manual venue-call support.
- Manual venue-call support only resolves or accepts a venue phone number, asks what the user wants to ask, and returns the phone number plus a prepared script for the user to call personally.
- Manual venue-call support must never show or trigger **Call using agent**. If neither trusted contact lookup nor user input supplies a number, show `No venue contact available` with the script.
- **Book or Buy Packages** may start a whole-page AI-assisted package/product search scoped to the current activity or venue.
- **Ask Agent Anything** may answer informational requests and recommend routing the user to **Call the Venue** or **Book or Buy Packages** when the request is better handled there.
- Booking CTAs may start an agent-assisted booking flow, including availability search and, where appropriate, a call conducted by the agent.
- The agent must present booking details, price, provider, cancellation terms when available, and uncertainty before asking for confirmation.
- Agent-assisted booking calls must resolve a venue point of contact before collecting reservation details. If the venue point of contact cannot be found through trusted sources, the user must be prompted to provide it manually.
- Agent-assisted booking calls must ask for requestor name, reservation date/time, party size, callback phone, and optional remarks in a step-by-step conversational flow.
- Reservation date/time must be parseable and in the future; invalid or past values must be rejected and re-asked.
- Before a booking call starts, the agent must present a summary of the request and the telephone script that Gemini Live will use. The user must be able to edit those details before confirmation.
- Reservation name, callback phone, user-provided venue hotline overrides, and remarks are per-request only and must not be saved into preferences.
- If venue phone lookup, Twilio, Gemini Live, public webhook/WSS URL, or user confirmation is unavailable, the agent must fall back to regular chat instructions and clearly state that no booking was made.
- Do not expose a **Use chat instructions** button in either manual or agent-assisted call flows. Any safe fallback guidance is shown directly in the conversation or call status.
- Package/product discovery must be activity-scoped. For example, a Singapore Zoo activity should search for Singapore Zoo tickets, tours, add-ons, and nearby authorized packages, not unrelated app-wide products.
- Package/product results must come from official or authorized providers where possible, such as venue ticketing pages, tour operators, booking platforms, public Stripe Payment Links, or Stripe-connected providers.
- Each result must show provider/source, price when available, cancellation/refund caveats when available, and confidence/source context before checkout handoff.
- Checkout may use Stripe-hosted checkout only when the verified provider exposes a Stripe-backed checkout, public Stripe Payment Link, or Wanderlust has a valid Stripe seller/Connect relationship for that product. Otherwise, the app opens the verified provider's external checkout page.
- Flutter must never contain Stripe secret keys or provider checkout secrets.
- Raw payment card data must never be stored in Flutter local storage or backend app storage. Do not store local saved-card data or local payment history for the provider-checkout flow unless a future explicit requirement adds a separate receipt feature.
- No booking, payment, or call commitment may be finalized without explicit user confirmation.
- After an agent-assisted booking call, the agent must report the result to the user, including success/failure, reservation details, and any follow-up needed.
- Twilio call execution may run on Google Cloud because Twilio requires public HTTPS/WSS callbacks. Twilio call logs may be stored in a Google Cloud database as a narrow exception to local-first persistence, but logs must be minimal and redacted.

## Agent Chat

After itinerary onboarding, the user can chat with an agent to:

- Change itinerary specs.
- Modify the whole trip.
- Modify only a day or subset of days.
- Add a place/activity/event between existing itinerary places.
- Ask travel questions.
- Ask why a recommendation exists.
- Ask for alternatives.
- Ask about booking, payment, or directions options.
- Ask for activity-scoped help through **Ask Agent Anything**.

Guardrails:

- The agent should preserve unchanged itinerary days when the user asks to modify only part of the trip.
- The agent should explain major itinerary changes before the user accepts them.
- The agent may directly add an activity/event/place into the local itinerary only when the user explicitly asks for an in-scope itinerary edit and the backend returns a validated structured mutation.
- Out-of-scope chat requests should be rejected politely.
- The agent should not silently activate, stop, delete, export, book, or buy without explicit user action.
- The agent should not place a booking call without explicit user confirmation of intent and key booking details.
- The agent must refuse payment-card handling during booking calls.
- The agent may recommend **Call the Venue** or **Book or Buy Packages** with a user-pressable CTA, but the informational chat itself must not place calls or initiate payment.

## Active Itinerary Behavior

When an itinerary is started:

- Status becomes ACTIVE.
- Starting an itinerary is the active mode for the app.
- Device location service may start only with active permission.
- Backend event ingestion starts.
- ADK ambient active workflows may run.
- Dynamic behavior preference learning may start.
- UI should indicate the itinerary is active.

When an itinerary is stopped:

- Status becomes INACTIVE unless it is explicitly completed.
- Device location service stops.
- Backend event ingestion stops.
- ADK ambient active workflows stop.
- Active suggestions stop.
- Dynamic behavior updates stop.

When an itinerary is marked as completed:

- Status becomes COMPLETED.
- Device location service stops.
- Backend event ingestion stops.
- ADK ambient active workflows stop.
- Active suggestions stop.
- Dynamic behavior updates stop.

Arrival recognition:

- The app should detect when the user arrives at a place in the active itinerary.
- The matching itinerary place should be highlighted in the UI.
- Arrival detection should tolerate GPS noise and should use place geometry, dwell time, and route context rather than a single coordinate ping.

Deviation and recovery:

- If the user does not follow the itinerary, the agent may recommend an updated itinerary personalized to observed habits and behavior.
- The user keeps the decision to apply the update.
- The user can accept the update, reject it, or chat with the agent to modify it.
- The user can request partial recovery, such as changing only the current day while keeping the rest of the trip unchanged.

## Dynamic Behavior Preferences

Dynamic behavior preferences capture how the user behaves during an active itinerary:

- Slow or fast pace.
- Longer or shorter dwell time.
- Meal timing.
- Rest patterns.
- Skipped place types.
- Extended interest in specific place types.
- Repeated late starts or early finishes.

Guardrails:

- Dynamic behavior preferences are itinerary-scoped by default.
- They can influence the active itinerary immediately.
- The most updated itinerary style can be added into long-term preferences only through an explicit user action, such as "Add style of this trip into preferences."
- Resetting or deleting preferences must affect future active recommendations immediately.

## Development Guardrails

- Never run active location, ambient agents, or active suggestions for INACTIVE or COMPLETED itineraries.
- Never allow more than one ACTIVE itinerary.
- Never implement active mode as a separate state from starting an itinerary.
- Never show a recommendation without a brief explanation/reasoning.
- Never treat social trend sources as factual authority.
- Never update the user's itinerary automatically after deviation; present the updated itinerary for user acceptance.
- Deviation checks should use saved stop coordinates first and route/geocode-resolved coordinates second. Missing coordinates must not be treated as proof of deviation.
- Never store dynamic behavior only in Markdown. Use structured storage as source of truth.
- Never let stale preferences continue influencing new active recommendations after the user modifies or resets them.
- Never delete saved itinerary data when resetting onboarding preferences.
- Never complete an itinerary automatically; completion is user-marked.
- Never finalize booking, payment, or booking calls without explicit user confirmation.
- Never store raw payment-card data in local persistence.
- Never expose Stripe secret keys to Flutter.
- Never let a model response alone redirect a call target or payment target without deterministic validation and user confirmation.
