# M3 Redesign — Deferred / Incomplete Items

This document tracks the parts of the Material 3 visual redesign plan that have
**not** been landed in the current PR, with the rationale for deferral. It is
intended as a hand-off note so the remaining work can be picked up safely in a
follow-up change with proper runtime verification.

See [`m3_redesign_plan.md`](./m3_redesign_plan.md) for the full plan and
phase/step numbering.

## Status legend

- ✅ Landed
- 🟡 Partially landed (sub-item incomplete — see notes)
- ⛔ Deferred (not landed in this PR)

## Per-step status

### Phase 1 — Foundation
- ✅ `dynamic_color`, M3 `ColorScheme`, `AppColours` `ThemeExtension`, typescale
  aliases.

### Phase 2 / 3 — App chrome
- 🟡 **Step 4 — `SliverAppBar.medium` migration** ⛔
  - **Done:** trailing initials `CircleAvatar` in `AppBar.actions` driven by
    `authorNameProvider` / `authorEmailProvider`, falling back to a
    `solidUser` icon when unauthenticated.
  - **Not done:** swap of the fixed `AppBar` for `SliverAppBar.medium`. The
    home tab is a ~4000-line widget tree built on a fixed `AppBar`; a Sliver
    migration requires reworking the surrounding scaffold and
    scroll-controller plumbing and is unsafe to land without runtime
    verification.

- 🟡 **Step 5 — Section headers + sync icon transition** ⛔ (header part)
  - **Done:** `AnimatedSwitcher` (scale) wrapping the home-tab sync button
    icon so it animates between recommended-action states.
  - **Not done:** `labelLarge` section headers ("Sync", "Recent Activity",
    "Repository") and the `Card` reflow that groups related controls. The
    sync controls live ~7 widget levels deep inside the same nested tree;
    reflowing them risks layout regressions without runtime testing.

### Phase 4 — Tools tab
- ✅ New `ToolsPage` + `NavigationDestination` wiring.

### Phase 5 — Components
- ✅ Step 9 — `ShowcaseFeatureButton` launcher-card redesign.
- ✅ Step 10 — Commit author avatar + 3 dp left-border accent replacing
  `ChevronPainter` + `Curves.easeOutCubic` enter transitions on the
  recent-commits `AnimatedListView`.
  - Note: `ChevronPainter` itself is no longer referenced from a build
    method; the class is left in place because removal is unrelated to the
    visual redesign and can be done in a dedicated cleanup commit.
- 🟡 **Step 11 — Branch selector** ⛔ (`DropdownMenu` swap)
  - **Done:** leading icon + `AnimatedSwitcher` for the selected branch
    label.
  - **Not done:** swapping the bespoke `showMenu` popup for a Material 3
    `DropdownMenu`. `DropdownMenu` does not natively support the per-item
    rename/delete inline action affordances rendered next to each branch
    today, so the swap would be a behavior regression rather than a visual
    refresh.
- ✅ Step 12 — `ButtonSetting` type enum + tooltip + sentence-case labels.
- ⛔ **Step 13 — `Card` grouping in settings** ⛔
  - **Not done:** wrapping related setting groups in M3 filled `Card`s.
    `settings_main.dart` only contains a single `ButtonSetting`; the bulk of
    the surface is `global_settings_main.dart` (~1061 lines of `ItemSetting`
    rows). Mechanical reflow without runtime testing carries a meaningful
    layout-regression risk; this should be done with a real device in the
    loop.

### Phase 7 — Issues / PRs
- ✅ Step 14 — Author avatars + status badges.

### Phase 8 — Polish
- 🟡 **Step 15 — Dialog refresh** ⛔ (`barrierColor` portion)
  - **Done:** `BaseAlertDialog` already accepts `icon`, satisfying the
    icon-header part of the step.
  - **Not done:** standardising a translucent `barrierColor` across every
    `showDialog` call site. The change is mechanical but touches dozens of
    unrelated call sites; it belongs in its own focused PR (or a small
    helper that wraps `showDialog`).
- ✅ Step 16 — `SyncLoader` scale-in + tooltip + haptic.
- ✅ Step 17 — Onboarding `LinearProgressIndicator` + `AnimatedSwitcher`
  fade between screens.
  - Note: implemented with `AnimatedSwitcher` rather than
    `AnimatedCrossFade` because the onboarding flow has more than two
    states.
- ✅ Step 18 — `ExpandedCommits` "Repository Tools" header.

## Summary of remaining work

Five concrete follow-ups, in roughly increasing risk order:

1. **Step 15 (`barrierColor`)** — wrap or standardise `showDialog` call
   sites with a translucent barrier colour. Low-risk, mechanical.
2. **Step 13 (settings `Card` grouping)** — primarily
   `global_settings_main.dart`; should be done with runtime verification on
   a device/emulator.
3. **Step 5 (section headers + home `Card` reflow)** — needs careful
   restructuring of the deeply-nested home widget tree.
4. **Step 11 (`DropdownMenu` swap)** — requires either dropping or
   re-implementing the per-item rename/delete affordances; design decision
   needed before code changes.
5. **Step 4 (`SliverAppBar.medium`)** — largest scope; touches the home
   `Scaffold` shell and the surrounding scroll plumbing.
