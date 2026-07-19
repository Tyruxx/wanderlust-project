---
name: Horizon Material
colors:
  surface: '#faf9fa'
  surface-dim: '#dadadb'
  surface-bright: '#faf9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f4'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e9'
  surface-container-highest: '#e3e2e3'
  on-surface: '#1a1c1d'
  on-surface-variant: '#40484f'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f0f1'
  outline: '#707880'
  outline-variant: '#c0c7d0'
  surface-tint: '#006495'
  primary: '#004b71'
  on-primary: '#ffffff'
  primary-container: '#006495'
  on-primary-container: '#b7ddff'
  inverse-primary: '#8fcdff'
  secondary: '#4f6354'
  on-secondary: '#ffffff'
  secondary-container: '#cfe5d2'
  on-secondary-container: '#536758'
  tertiary: '#53452a'
  on-tertiary: '#ffffff'
  tertiary-container: '#6c5d40'
  on-tertiary-container: '#ecd7b2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cbe6ff'
  primary-fixed-dim: '#8fcdff'
  on-primary-fixed: '#001e30'
  on-primary-fixed-variant: '#004b71'
  secondary-fixed: '#d2e8d5'
  secondary-fixed-dim: '#b6ccba'
  on-secondary-fixed: '#0d1f14'
  on-secondary-fixed-variant: '#384b3d'
  tertiary-fixed: '#f5e0bb'
  tertiary-fixed-dim: '#d8c4a1'
  on-tertiary-fixed: '#241a04'
  on-tertiary-fixed-variant: '#53452a'
  background: '#faf9fa'
  on-background: '#1a1c1d'
  surface-variant: '#e3e2e3'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 57px
    fontWeight: '400'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-desktop: 24px
  gutter: 16px
  container-padding: 24px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
---

## Brand & Style
The design system is a refined interpretation of Material Design 3 (MD3), specifically tailored for modern travel. It evokes a sense of calm, wanderlust, and reliability. The target audience consists of organized travelers who value clarity and ease of use during high-stress transit or exploration.

The visual style is **Corporate / Modern** with a lean toward **Minimalism**. It utilizes the MD3 "State of Mind" philosophy, focusing on adaptive layouts, expressive motion, and a tactile surface-driven hierarchy. The experience is intentionally "clutter-free," prioritizing high-value information—like flight times and gate numbers—through generous whitespace and a rigorous grid.

## Colors
The palette is rooted in nature and sky tones, utilizing a sophisticated MD3 tonal palette.
- **Primary (Sky):** A deep, reliable blue representing the horizon and aviation. Used for key actions and active states.
- **Secondary (Nature):** An earthy, muted green inspired by landscapes and parks. Used for supporting elements and travel categories.
- **Tertiary (Earth):** A soft sand/wood tone for highlights like cultural sites or historical notes.
- **Surface & Neutrals:** Off-white "Sky" tints for surfaces to reduce eye strain, with cool-toned grays for secondary text and outlines.

Apply color through the MD3 tonal system: use `on-primary` for text atop primary backgrounds and `surface-container-high` for elevated cards.

## Typography
This design system pairs **Plus Jakarta Sans** for headlines with **Inter** for body and functional text.
- **Plus Jakarta Sans** provides a welcoming, contemporary feel with its soft curves, perfect for travel titles and destinations.
- **Inter** ensures maximum legibility for dense itinerary information, flight codes, and timestamps.
- **Weight Strategy:** Use Medium (500) for labels and titles to ensure they stand out against surface containers. Use Regular (400) for long-form content.
- **Accessibility:** Maintain a minimum of 4.5:1 contrast ratio for all body copy.

## Layout & Spacing
Following MD3's fluid grid philosophy, this design system uses an **8px base unit**.
- **Mobile:** 4-column grid with 16px margins.
- **Tablet:** 8-column grid with 24px margins.
- **Desktop:** 12-column grid with a max-width of 1200px, centered with flexible margins.

Spacing should emphasize vertical rhythm. Use `stack-lg` (24px) to separate different days in an itinerary and `stack-md` (12px) to separate individual items (flights, hotels) within a single day.

## Elevation & Depth
In accordance with MD3, depth is primarily communicated through **Tonal Layers** rather than heavy shadows.
- **Level 0 (Surface):** The lowest layer, using the base surface color.
- **Level 1 (Card/Container):** Uses a slightly tinted version of the surface color (Surface Container) with no shadow.
- **Level 2 (Floating/Active):** Uses a subtle shadow (blur 8px, opacity 0.08, 2px offset) to indicate interactivity or modal status.
- **Outlines:** Use 1px `outline-variant` borders for low-priority containers (like secondary cards) to maintain a clean, flat look without sacrificing structure.

## Shapes
The shape language is highly organic and friendly.
- **Small Components:** Buttons and chips use a `rounded-lg` (16px) or full pill shape.
- **Medium Components:** Text fields and small cards use `rounded-lg` (12px-16px).
- **Large Components:** Main itinerary containers, bottom sheets, and hero cards use **Extra Large** roundedness (28px) to create a soft, inviting aesthetic that feels safe and modern.

## Components
- **Buttons:** MD3 filled buttons for primary actions (e.g., "Add Event"). Outlined buttons for secondary actions (e.g., "View Map"). All buttons have 40px minimum height for touch accessibility.
- **Cards:** Use "Elevated" cards for the current/active travel event and "Outlined" or "Filled" (low tonal) cards for past or future events to create a visual timeline hierarchy.
- **Chips:** Used for tags like "Flight," "Hotel," or "Dining." Use the Secondary color palette for a nature-inspired distinction.
- **Lists:** High-density lists for itineraries must include left-aligned icons (e.g., plane, bed) and right-aligned timestamps.
- **Input Fields:** Filled text fields with a bottom indicator line, utilizing the Primary color for the focus state.
- **Navigation:** Use a Navigation Bar (bottom) for mobile and a Navigation Rail or Drawer for desktop, following MD3's signature pill-shaped active state indicator.
