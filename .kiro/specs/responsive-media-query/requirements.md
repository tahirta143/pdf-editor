# Requirements Document

## Introduction

This feature makes the PDF Editor App fully responsive by introducing a centralized `ResponsiveHelper` utility that uses Flutter's `MediaQuery` to derive breakpoints, scaled dimensions, and adaptive layout values. Every screen — Splash, Navigation, Home, Settings, About, and all 14 PDF tool screens — will replace hardcoded pixel values with responsive equivalents so the UI renders correctly on small phones (≤360 dp), standard phones (361–414 dp), large phones / small tablets (415–600 dp), and tablets (>600 dp).

## Glossary

- **App**: The PDF Editor Flutter application (`pdfeditorapp`).
- **ResponsiveHelper**: A utility class/extension that wraps `MediaQuery` and exposes scaled spacing, font sizes, icon sizes, and breakpoint booleans.
- **Screen_Width**: The logical pixel width returned by `MediaQuery.of(context).size.width`.
- **Screen_Height**: The logical pixel height returned by `MediaQuery.of(context).size.height`.
- **Breakpoint**: A Screen_Width threshold that separates layout tiers — `compact` (≤360 dp), `standard` (361–414 dp), `expanded` (415–600 dp), `tablet` (>600 dp).
- **Hardcoded_Value**: Any literal pixel/font size constant in a widget that does not scale with Screen_Width or Screen_Height.
- **Adaptive_Grid**: A `GridView` whose `crossAxisCount` changes based on the active Breakpoint.
- **Safe_Area**: The region of the screen not obscured by system UI, accessed via `MediaQuery.of(context).padding`.
- **Orientation**: Portrait or landscape, derived from `MediaQuery.of(context).orientation`.

---

## Requirements

### Requirement 1: Centralized Responsive Utility

**User Story:** As a developer, I want a single source of truth for responsive values, so that I can apply consistent scaling across every screen without duplicating MediaQuery logic.

#### Acceptance Criteria

1. THE App SHALL provide a `ResponsiveHelper` class accessible from any widget via `ResponsiveHelper.of(context)`.
2. WHEN `ResponsiveHelper.of(context)` is called, THE `ResponsiveHelper` SHALL read `MediaQuery.of(context)` exactly once and cache the result for that build cycle.
3. THE `ResponsiveHelper` SHALL expose a `breakpoint` getter that returns one of `compact`, `standard`, `expanded`, or `tablet` based on Screen_Width thresholds.
4. THE `ResponsiveHelper` SHALL expose a `scale(double base)` method that returns a value proportional to Screen_Width relative to a 390 dp reference width.
5. THE `ResponsiveHelper` SHALL expose `sp(double fontSize)` for font scaling, `wp(double percent)` for percentage-of-width values, and `hp(double percent)` for percentage-of-height values.
6. THE `ResponsiveHelper` SHALL expose `isTablet`, `isExpanded`, `isLandscape` boolean getters derived from the active Breakpoint and Orientation.

---

### Requirement 2: Responsive Splash Screen

**User Story:** As a user, I want the splash screen logo to be appropriately sized on any device, so that it does not appear too small on tablets or overflow on compact phones.

#### Acceptance Criteria

1. WHEN the Splash screen is rendered, THE Splash SHALL display the logo with a size equal to `ResponsiveHelper.wp(28)` (28 % of Screen_Width), clamped between 80 dp and 160 dp.
2. IF Screen_Width is greater than 600 dp, THEN THE Splash SHALL center the logo within a constrained box of maximum width 400 dp.

---

### Requirement 3: Responsive Bottom Navigation Bar

**User Story:** As a user, I want the bottom navigation bar to scale its height and icon sizes on larger screens, so that touch targets remain comfortable without wasting space.

#### Acceptance Criteria

1. THE Navigation bar height SHALL be `ResponsiveHelper.hp(8)` (8 % of Screen_Height), clamped between 56 dp and 80 dp.
2. THE Navigation bar icon size SHALL be `ResponsiveHelper.scale(28)`.
3. THE Navigation bar label font size SHALL be `ResponsiveHelper.sp(11)`.

---

### Requirement 4: Responsive Home Screen Layout

**User Story:** As a user, I want the tool grid on the Home screen to show more columns on wider screens, so that I can see more tools at once on tablets without oversized cards.

#### Acceptance Criteria

1. WHEN the Home screen is rendered on a `compact` or `standard` Breakpoint, THE Home SHALL display the tool grid with `crossAxisCount` of 3.
2. WHEN the Home screen is rendered on an `expanded` Breakpoint, THE Home SHALL display the tool grid with `crossAxisCount` of 4.
3. WHEN the Home screen is rendered on a `tablet` Breakpoint, THE Home SHALL display the tool grid with `crossAxisCount` of 5.
4. THE Home screen header image height SHALL be `ResponsiveHelper.hp(18)` (18 % of Screen_Height).
5. THE Home screen AppBar title font size SHALL be `ResponsiveHelper.sp(22)`.
6. THE tool card icon container size SHALL be `ResponsiveHelper.scale(45)`.
7. THE tool card title font size SHALL be `ResponsiveHelper.sp(11)`.
8. THE tool card subtitle font size SHALL be `ResponsiveHelper.sp(9)`.
9. THE Home screen grid horizontal padding SHALL be `ResponsiveHelper.wp(3)`.

---

### Requirement 5: Responsive Settings Screen

**User Story:** As a user, I want the Settings screen to use proportional spacing and font sizes, so that it looks balanced on both small phones and tablets.

#### Acceptance Criteria

1. THE Settings screen body padding SHALL be `ResponsiveHelper.wp(4)` on all sides.
2. THE save-location toggle container width SHALL be `ResponsiveHelper.wp(85)`, clamped to a maximum of 400 dp.
3. THE save-location toggle container height SHALL be `ResponsiveHelper.scale(40)`.
4. THE Settings section header font size SHALL be `ResponsiveHelper.sp(15)`.
5. THE Settings list tile subtitle font size SHALL be `ResponsiveHelper.sp(12)`.
6. IF Screen_Width is greater than 600 dp, THEN THE Settings screen SHALL constrain its content to a centered column of maximum width 600 dp.

---

### Requirement 6: Responsive About Screen

**User Story:** As a user, I want the About screen avatar, text, and feature list to scale correctly on all screen sizes, so that nothing appears clipped or disproportionately large.

#### Acceptance Criteria

1. THE About screen avatar radius SHALL be `ResponsiveHelper.scale(55)`.
2. THE About screen app name font size SHALL be `ResponsiveHelper.sp(22)`.
3. THE About screen version font size SHALL be `ResponsiveHelper.sp(14)`.
4. THE About screen description font size SHALL be `ResponsiveHelper.sp(13)`.
5. THE About screen body padding SHALL be `ResponsiveHelper.wp(4)`.
6. IF Screen_Width is greater than 600 dp, THEN THE About screen SHALL constrain its content to a centered column of maximum width 600 dp.

---

### Requirement 7: Responsive PDF Tool Screens (Common Patterns)

**User Story:** As a user, I want all PDF tool screens (Compress, Crop, Delete Pages, Extract Pages, Fill & Sign, HTML to PDF, Image to PDF, Merge, PDF Editor, PDF to Image, PDF to Word, Protect, Split, Unlock) to use responsive sizing, so that buttons, inputs, and toolbars are usable on any device.

#### Acceptance Criteria

1. THE action button vertical padding on all tool screens SHALL be `ResponsiveHelper.hp(2)` (2 % of Screen_Height).
2. THE action button border radius SHALL be `ResponsiveHelper.scale(30)`.
3. THE toolbar container height on screens that include a formatting toolbar (PDF Editor, Fill & Sign) SHALL be `ResponsiveHelper.scale(60)`.
4. THE toolbar horizontal margin SHALL be `ResponsiveHelper.wp(2.5)`.
5. THE empty-state icon size on all tool screens SHALL be `ResponsiveHelper.scale(80)`.
6. THE screen body horizontal padding SHALL be `ResponsiveHelper.wp(5)` on compact/standard Breakpoints and `ResponsiveHelper.wp(8)` on expanded/tablet Breakpoints.
7. WHEN a success overlay is displayed, THE success icon size SHALL be `ResponsiveHelper.scale(80)` and the success message font size SHALL be `ResponsiveHelper.sp(17)`.

---

### Requirement 8: Responsive PDF Viewer Integration

**User Story:** As a user, I want the PDF viewer and signature pad to occupy the correct proportion of the screen on any device, so that I can read and annotate documents comfortably.

#### Acceptance Criteria

1. WHEN the Fill & Sign signature bottom sheet is displayed, THE bottom sheet height SHALL be `ResponsiveHelper.hp(80)` (80 % of Screen_Height).
2. THE bottom toolbar height on the Fill & Sign screen SHALL be `ResponsiveHelper.scale(60)`.
3. THE PDF viewer SHALL expand to fill all remaining vertical space after the AppBar and any toolbar using a `Flexible` or `Expanded` widget, regardless of screen size.

---

### Requirement 9: Orientation Adaptability

**User Story:** As a user, I want the app layout to adapt when I rotate my device, so that landscape mode makes better use of the wider viewport.

#### Acceptance Criteria

1. WHEN Orientation is landscape and the active Breakpoint is `compact` or `standard`, THE Home screen grid `crossAxisCount` SHALL increase by 1 compared to the portrait value.
2. WHEN Orientation is landscape, THE Home screen header image height SHALL be `ResponsiveHelper.hp(25)`.
3. WHEN Orientation changes, THE App SHALL rebuild affected widgets without requiring a hot restart.

---

### Requirement 10: Theme-Level Responsive Text Styles

**User Story:** As a developer, I want the global `ThemeData` in `main.dart` to use responsive font sizes, so that AppBar titles and button labels scale consistently without per-widget overrides.

#### Acceptance Criteria

1. THE `AppBarTheme.titleTextStyle` font size in `main.dart` SHALL be replaced with a value derived from `ResponsiveHelper` or a `TextTheme` that scales with the device's `textScaleFactor`.
2. THE `ElevatedButtonTheme` and `OutlinedButtonTheme` padding in `main.dart` SHALL use `EdgeInsets.symmetric` values derived from `ResponsiveHelper.hp` and `ResponsiveHelper.wp` rather than fixed pixel constants.
3. WHEN the system text scale factor changes, THE App text SHALL reflow without overflow or clipping on any screen covered by Requirements 2–9.
