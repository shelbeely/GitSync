# M3 Visual Redesign & Tools Tab — Plan

This is the full plan that drove the Material 3 visual refresh and the new
**Tools** tab. It is preserved here for reference; for the current
landed/not-landed status see
[`m3_redesign_deferred.md`](./m3_redesign_deferred.md).

## Goals

1. Adopt Material 3 colour, typography, shape and motion across the app
   without a destabilising rewrite.
2. Surface repository tooling (branches, issues, PRs, etc.) under a
   dedicated **Tools** tab so the home tab can stay focused on sync.
3. Keep every step landable in isolation so progress can ship incrementally.

## Phases & steps

### Phase 1 — Foundation

- **Step 1 — Theme primitives.** Adopt `dynamic_color` and define a Material 3
  `ColorScheme` for both light and dark. Expose the existing semantic palette
  through an `AppColours` `ThemeExtension` so widgets can read
  `Theme.of(context).extension<AppColours>()` without breaking the existing
  `colours.*` global accessors.
- **Step 2 — Typescale aliases.** Map the existing `textXS … textXXL` constants
  onto the M3 typescale (`labelSmall` … `displayLarge`) so future code can use
  either spelling without drift.
- **Step 3 — Shape & motion tokens.** Standardise corner radii on
  `cornerRadiusSM/MD/LG/Max` and motion durations on `animShort/Medium/Slow`
  with M3-aligned curves (`Curves.easeOutCubic`, `Curves.easeInOut`).

### Phase 2 — App shell

- **Step 4 — Top app bar refresh.** Migrate the home `AppBar` to
  `SliverAppBar.medium` with the title sliding from large → small on scroll,
  and add a trailing initials `CircleAvatar` driven by the authenticated git
  author identity (`authorNameProvider` / `authorEmailProvider`). Fall back to
  a generic person icon when unauthenticated.

### Phase 3 — Home tab

- **Step 5 — Layout & feedback.** Group sync controls, recent activity and
  repository status into M3 filled `Card`s with `labelLarge` section headers
  ("Sync", "Recent Activity", "Repository"). Wrap the sync button icon in an
  `AnimatedSwitcher` so it animates between recommended-action states.

### Phase 4 — Navigation & Tools tab

- **Step 6 — Bottom nav.** Switch the bottom bar to `NavigationBar` with
  `NavigationDestination` items (Sync, Tools, Settings).
- **Step 7 — New `ToolsPage`.** Introduce a Tools page that surfaces:
  branches, issues, pull requests, recent commits and any future
  repository-level tooling.
- **Step 8 — Wire-up.** Move tool-related entry points off the home tab and
  into Tools so the home tab is solely sync-focused.

### Phase 5 — Components

- **Step 9 — `ShowcaseFeatureButton` redesign.** Treat each launcher tile as
  an M3 filled `Card` with leading icon, title, supporting text and trailing
  chevron.
- **Step 10 — Commit list items.** Add an author `CircleAvatar`, replace the
  `ChevronPainter` diagonal-stripe accent with a 3 dp left-border colour
  accent driven by sync state (`unpushed`/`unpulled`), and animate the list
  itself with `Curves.easeOutCubic` enter transitions.
- **Step 11 — Branch selector.** Add a leading icon and an `AnimatedSwitcher`
  around the selected branch label, then swap the bespoke `showMenu` popup
  for a Material 3 `DropdownMenu` (preserving inline rename/delete
  affordances).
- **Step 12 — `ButtonSetting`.** Replace stringly-typed style flags with a
  `ButtonSettingType` enum, add a tooltip prop, and switch labels to sentence
  case (drop the manual `.toUpperCase()`).
- **Step 13 — Settings `Card` grouping.** Wrap related groups of
  `ItemSetting` / `ButtonSetting` rows in M3 filled `Card`s with
  `labelLarge` section headers across `settings_main.dart` and
  `global_settings_main.dart`.

### Phase 6 — Theming reach

- (Implicit, driven by Phase 1 — every screen consumes the new
  `ColorScheme`/typescale via the existing `colours.*` accessors plus the
  `AppColours` extension.)

### Phase 7 — Issues / PRs

- **Step 14 — Item refresh.** Add author `AuthorAvatar`s and status badges
  (open / merged / closed / draft) to issue and pull-request rows so they
  match the M3 list-item visual language.

### Phase 8 — Polish

- **Step 15 — Dialog refresh.** Standardise dialog headers with an optional
  leading icon (already supported by `BaseAlertDialog`) and a translucent
  `barrierColor` across every `showDialog` call site.
- **Step 16 — `SyncLoader`.** Scale-in animation, tooltip, and haptic
  feedback when the sync state changes.
- **Step 17 — Onboarding.** Add a `LinearProgressIndicator` showing
  flow progress, and cross-fade between screens (`AnimatedSwitcher` /
  `AnimatedCrossFade`).
- **Step 18 — `ExpandedCommits` polish.** Add a "Repository Tools" header
  block matching the new Tools-tab visual language.

## Implementation principles

- **Smallest viable change.** Each step is independently landable; partial
  steps are split (and recorded in `m3_redesign_deferred.md`) when the rest
  of the step would require risky restructuring without runtime testing.
- **Reuse existing primitives.** Prefer extending `AppColours`, the `dimens`
  constants and existing components (`AuthorAvatar`, `BaseAlertDialog`,
  `ButtonSetting`, …) over introducing parallel implementations.
- **No regressions to behaviour.** Visual refresh only — no functional
  changes, no provider restructuring, no API changes.
