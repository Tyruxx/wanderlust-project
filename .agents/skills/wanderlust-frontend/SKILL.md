---
name: wanderlust-frontend
description: Use this skill for every Wanderlust Trip Flutter frontend task before editing screens, widgets, styles, themes, navigation, state, or assets. It references the Horizon Material design system in specs/DESIGN.md and the product guardrails in specs/03-product-workflows-and-guardrails.md.
---

# Wanderlust Frontend

Use this skill before any change to Flutter UI code: screens, widgets, styles,
navigation, state management, assets, or theming. The authoritative design
reference is `specs/DESIGN.md` (Horizon Material). The authoritative product
constraints reference is `specs/03-product-workflows-and-guardrails.md`.

---

## Design Reference

The full Horizon Material design system lives in `../specs/DESIGN.md`. This
skill extracts the core rules that Flutter code must follow.

## Colors

Use `AppColors` from `app/app_theme.dart`. Never hardcode color values.

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#004B71` | Key actions, active states, primary buttons |
| `primaryContainer` | `#006495` | Elevated surfaces, active cards |
| `secondary` | `#4F6354` | Supporting elements, chips, categories |
| `tertiary` | `#6C5D40` | Cultural/historical highlights |
| `surface` | `#FAF9FA` | Page backgrounds (off-white "Sky") |
| `surfaceContainer` | `#EEEEEE` | Card/container backgrounds |
| `outline` | `#C0C7D0` | Borders, dividers |
| `text` | `#1A1C1D` | Primary body text |
| `muted` | `#40484F` | Secondary text, captions |
| `error` | `#BA1A1A` | Errors, destructive actions |

Apply color through MD3 tonal system: use `on-primary` for text atop primary
backgrounds, `surface-container-high` for elevated cards.

## Typography

Two font families: **Plus Jakarta Sans** (headlines) and **Inter** (body).

| Theme token | Font | Size | Weight | Line Height | Usage |
|-------------|------|------|--------|-------------|-------|
| `headlineLarge` | Plus Jakarta Sans | 28px | w400 | 1.25 | Page titles, day headers |
| `headlineSmall` | Plus Jakarta Sans | 24px | w500 | 1.25 | Section headers |
| `titleLarge` | Plus Jakarta Sans | 22px | w500 | 1.27 | Card titles |
| `titleMedium` | Inter | 16px | w600 | 1.45 | Labels, button text |
| `bodyLarge` | Inter | 16px | w400 | 1.50 | Body content, descriptions |
| `bodyMedium` | Inter | 14px | w400 | 1.42 | Secondary text, metadata |
| `labelLarge` | Inter | 14px | w600 | — | Category labels, chips |
| `labelSmall` | Inter | 11px | w600 | — | Timestamps, captions |

**Rules:**

- Never override `fontSize` with a hardcoded value. Use the theme token directly.
  If a token does not exist, add it to `app_theme.dart` and `specs/DESIGN.md`.
- Use `copyWith` only for color, weight, or other non-size adjustments.
- Maintain minimum 4.5:1 contrast ratio for body copy.

## Layout & Spacing

- **Base unit:** 8px. All spacing values should be multiples of 4.
- **Mobile margins:** 16px. **Desktop/tablet margins:** 24px.
- **Vertical rhythm:** Use 24px (`stack-lg`) to separate days, 12px (`stack-md`)
  for items within a day, 4px (`stack-sm`) for tight groups.
- **Grid:** Mobile 4-column, tablet 8-column, desktop 12-column.

## Elevation & Depth

- **Level 0:** `surface` color — page backgrounds.
- **Level 1 (cards):** White background with 1px `outline` border, no shadow.
  Use `Card` with `elevation: 0` and `shape: RoundedRectangleBorder`.
- **Level 2 (floating/active):** Subtle shadow (`blurRadius: 8`, `offset: 0,2`,
  `color: black @ 8%`). Used for modals, FABs, active-state cards.
- **Outlines:** Use 1px `AppColors.outline` for card borders.

## Shapes

- **Pill/full:** `BorderRadius.circular(999)` — buttons, chips, day toggles.
- **Large (28px):** Bottom sheets, hero cards, main containers.
- **Medium (16-18px):** Text fields, small cards, `Card` shape.
- **Small (12px):** Dense cards, compact containers.

## Components

- **Buttons:** Filled buttons for primary actions (min height 48px). Outlined
  buttons for secondary actions (min height 44px). Pill shape preferred.
- **Cards:** `elevation: 0`, white background, `outline` border, 18px radius.
  Active/current cards use `primary` border (2px) and tinted background.
- **Chips:** `ActionChip` for inline actions. Secondary palette for category tags.
- **Text fields:** Filled, `labelText`, 16px border radius. Primary color for focus.
- **Bottom sheets:** `DraggableScrollableSheet` with 28px top radius.
- **FAB:** `FloatingActionButton.extended` for primary screen actions (chat, add).
  `foregroundColor: Colors.white`.

## Product Guardrails (from specs/03)

The Flutter UI must enforce these constraints:

- **Preference onboarding** must complete before itinerary generation.
- **Only one** itinerary may be ACTIVE at a time.
- **Starting** another ACTIVE trip requires explicit user confirmation dialog.
- **Stop/Complete** immediately halts active location, ambient workflows, and
  suggestions.
- **INACTIVE** and **COMPLETED** itineraries must not show active-location UI.
- **Reset preferences** returns to onboarding, does not delete saved itineraries.
- **Recommendations** must include confidence or source context.
- **Social-only** suggestions must be marked exploratory.
- Sensitive actions (delete, export, start, stop, complete, booking) require
  explicit user action — never from agent chat alone.

## State & Data Flow

- `AppState` (`state/app_state.dart`) is the single source of truth via
  `ChangeNotifier`. Widgets access it through `AppStateScope.of(context)`.
- Use `AnimatedBuilder(animation: appState, builder: ...)` in screens that
  react to state changes.
- Local SQLite persistence through `LocalDatabaseService`
  (`services/local_database_service.dart`).
- Backend API calls through `BackendApiClient`
  (`services/backend_api_contract.dart`).

## File Structure

```
lib/
├── app/                    # App shell, theme, config
│   ├── app_theme.dart      # AppColors, buildAppTheme()
│   ├── app_config.dart     # Env-based config
│   └── travel_app.dart     # Root widget
├── features/               # Feature modules
│   ├── auth/               # Auth gate, splash
│   ├── itinerary/          # List, detail, add, chat
│   ├── onboarding/         # Preference onboarding
│   └── preferences/        # Preference management
├── models/                 # Data models
├── services/               # Backend API, local DB
├── shared/                 # Shared widgets
└── state/                  # AppState
```

## Required Checks for Frontend Changes

1. Run `flutter analyze` — must pass with no issues.
2. Verify no hardcoded font sizes, colors, or spacing — use theme tokens.
3. Verify product guardrails are preserved in UI logic.
4. Verify that text retains minimum 4.5:1 contrast ratio.
5. Run security audit (`../wanderlust-agentic-security/SKILL.md`) if the change
   touches API keys, persistence, or user data.
