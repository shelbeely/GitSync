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
    verification on phone and tablet form factors. Still deferred — explicit
    runtime device verification required.

- 🟡 **Step 5 — Section headers + sync icon transition** ⛔ (header part)
  - **Done:** `AnimatedSwitcher` (scale) wrapping the home-tab sync button
    icon so it animates between recommended-action states.
  - **Not done:** `labelLarge` section headers ("Sync", "Recent Activity",
    "Repository") and the `Card` reflow that groups related controls. The
    sync controls live ~7 widget levels deep inside the same nested tree;
    reflowing them risks layout regressions without runtime testing. Still
    deferred — should be done alongside the Step 4 Sliver migration.

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
- 🟡 **Step 11 — Branch selector** 🟡 (`DropdownMenu` swap, partial)
  - **Done:** leading icon + `AnimatedSwitcher` for the selected branch
    label. M3 surface tokens applied to the existing `showMenu` popup
    (`cornerRadiusMD`, level-2 elevation, `surfaceTintColor: transparent`,
    `clipBehavior: antiAlias`) — option (a) from the deferred plan.
  - **Not done:** full swap to a Material 3 `DropdownMenu` widget.
    `DropdownMenu` does not natively support the per-item rename/delete
    inline action affordances rendered next to each branch today, so the
    swap would be a behavior regression rather than a visual refresh. The
    chosen incremental step (a) preserves all existing affordances.
- ✅ Step 12 — `ButtonSetting` type enum + tooltip + sentence-case labels.
- 🟡 **Step 13 — `Card` grouping in settings** 🟡
  - **Done:** new shared `SettingsSection` widget
    (`lib/ui/component/settings_section.dart`) provides a `labelLarge`
    section header followed by an M3 filled `Card` that visually groups
    related rows. Applied across `global_settings_main.dart` for the
    "Backup & Restore", "Community", "Guides", "Repository Defaults",
    "Miscellaneous" and (with negative tint) "Danger Zone" sections — the
    bespoke rule-text-rule dividers were replaced.
  - **Not done:** `settings_main.dart` only contains a single `ButtonSetting`
    plus misc content with no existing section labels; adding headers there
    would require new translation strings across 8 locales and is best done
    as a focused l10n PR.

### Phase 7 — Issues / PRs
- ✅ Step 14 — Author avatars + status badges.

### Phase 8 — Polish
- ✅ **Step 15 — Dialog refresh** ✅ (`barrierColor` portion)
  - **Done:** `BaseAlertDialog` already accepts `icon`, satisfying the
    icon-header part of the step.
  - **Done:** new `showAppDialog` helper in
    `lib/ui/dialog/dialog_utils.dart` wraps Flutter's `showDialog` and
    injects a consistent translucent `barrierColor` (`Colors.black54`) on
    every call site. All 57 dialog wrappers under `lib/ui/dialog/` and the
    six direct call sites in `ai_features_page.dart` and `ai_wand_field.dart`
    now use the helper; unused `as mat` aliases were removed. Sites that
    explicitly need a transparent scrim (`manual_sync.dart`) override the
    default by passing `barrierColor: Colors.transparent`.
- ✅ Step 16 — `SyncLoader` scale-in + tooltip + haptic.
- ✅ Step 17 — Onboarding `LinearProgressIndicator` + `AnimatedSwitcher`
  fade between screens.
  - Note: implemented with `AnimatedSwitcher` rather than
    `AnimatedCrossFade` because the onboarding flow has more than two
    states.
- ✅ Step 18 — `ExpandedCommits` "Repository Tools" header.

## Summary of remaining work

After the follow-up implementation pass:

1. ✅ **Step 15 (`barrierColor`)** — landed via the new `showAppDialog`
   helper.
2. 🟡 **Step 13 (settings `Card` grouping)** — landed for
   `global_settings_main.dart`; `settings_main.dart` still pending pending
   l10n strings for any added section labels.
3. 🟡 **Step 11 (branch selector)** — M3 surface tokens applied to the
   existing `showMenu` (option (a) from the plan); a full `DropdownMenu`
   swap remains blocked on a design decision about per-item rename/delete
   affordances.
4. ⛔ **Step 5 (section headers + home `Card` reflow)** — still requires
   runtime device verification across the deeply-nested home widget tree.
5. ⛔ **Step 4 (`SliverAppBar.medium`)** — still requires runtime
   verification on phone and tablet form factors.
