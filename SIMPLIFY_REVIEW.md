# Simplify Review: `feature/recent-activity-width-fill`

> Commit: `a18bcd6` — Replace derived active milestone with explicit isActive flag and width-responsive recent activity

This review separates branch-introduced issues from pre-existing cleanup so the follow-up work can stay focused.

**Scope labels**

- **Introduced:** New issue from this branch.
- **Worsened:** Existing pattern made more important by this branch.
- **Pre-existing:** Worth tracking, but not caused by this branch.
- **Nit:** Low-risk cleanup; do only if already touching the area.

---

## 1. Code Reuse

### 1.1 Duplicate PreferenceKey for Width Measurement

**Scope:** Nit

`TitleRowWidthKey` (GoalRowView.swift:146-151) and `RecentActivityWidthKey` (RecentActivityView.swift:88-93) are structurally identical — only the name differs.

**Recommendation:** Do not treat this as high-priority. These are small private types and the explicit names carry useful local meaning. If more width-measurement keys appear, extract a shared optional-width preference key then.

### 1.2 Repeated Width Validation Pattern

**Scope:** Nit

Both files check finite optional `CGFloat` widths before storing or emitting them:

- GoalRowView.swift:88-94
- RecentActivityView.swift:34 and 79

**Recommendation:** Leave as-is unless this pattern spreads further. A helper such as `validFiniteWidth(_:)` is only worthwhile if it improves more than these two call sites.

### 1.3 Min/Max Clamp Pattern

**Scope:** Nit

`min(max(value, lowerBound), upperBound)` appears in a few places, including:

- MilestoneGoalRepository.swift:129
- RecentActivityView.swift:85
- FinalGoalStore.swift:106

**Recommendation:** A `clamped(to:)` extension could help, but this is not branch-critical. Avoid adding a general utility just for two or three obvious numeric bounds.

### 1.4 Refresh+Widget Reload Pattern

**Scope:** Pre-existing

`MilestoneGoalStore.refreshAndReloadWidget(finalGoalID:)` mirrors part of `FinalGoalStore.refreshAndReloadWidget()`, but they are not identical:

- `FinalGoalStore` refreshes final goals and reloads widget timelines.
- `MilestoneGoalStore` refreshes milestones for one final goal, reloads widget timelines, and calls `onMilestonesChanged?()`.

**Recommendation:** Correctness does not require a shared helper right now. If more stores need this pattern, extract a small widget reload helper, not a store protocol.

---

## 2. Code Quality

### 2.1 Manual Title/Tag Width Layout

**Scope:** Introduced

**GoalRowView.swift:49-51**

```swift
let tagWidth: CGFloat = milestone.isActive ? 50
    : (milestone.completedAt == nil ? 58 : 20)
let titleMaxWidth = titleRowWidth.map { max(0, ($0 - tagWidth) * 0.8) } ?? .infinity
```

The hardcoded tag widths and unexplained `0.8` multiplier are one layout workaround, not two separate problems. This can break with localization, accessibility sizes, font changes, and different system rendering.

**Recommendation:** Replace the manual width math with SwiftUI layout behavior. Prefer giving the title a lower layout priority or fixed maximum behavior while letting the badge/checkmark size itself with `fixedSize()`. If a ratio is still necessary, name it and explain why the title should intentionally leave spare room.

### 2.2 Free Layout Functions in Global Namespace

**Scope:** Introduced

`computeVisibleRecentActivityDayCount()` and `computeRequiredRecentActivityDayLimit()` are layout-specific helpers currently defined as global functions in RecentActivityView.swift.

They are not only used by `RecentActivityView`; tests call them directly in `VisibleActivityDayCountTests`.

**Recommendation:** Move them under `RecentActivityLayout` as internal static methods, then update tests to call `RecentActivityLayout.computeVisibleDayCount(...)`. Do not simply mark them `private` unless tests are moved into the same file/module strategy.

### 2.3 Nested Ternary for Tag Width

**Scope:** Nit

The nested ternary in GoalRowView.swift:49-50 is hard to scan.

**Recommendation:** This disappears if 2.1 removes manual width math. If width math remains, replace the ternary with a small computed property or `switch`.

### 2.4 Double-Negative Guard Logic

**Scope:** Nit

**MilestoneGoalRepository.swift:111-112**

```swift
guard !isActive || finalGoal.isActive else { throw ... }
guard !isActive || milestone.completedAt == nil else { throw ... }
```

**Recommendation:** Wrap the validations in `if isActive { ... }` for readability. This is a clarity improvement, not a correctness issue.

### 2.5 Parameter Count on MilestoneGoalRowView

**Scope:** Watch

`MilestoneGoalRowView` has 8 stored inputs: the milestone, read-only flag, and 6 callbacks. The interface is getting busy but is still understandable for a SwiftUI row.

**Recommendation:** Do not introduce `MilestoneActions` yet unless more callbacks are added or the same callback group is reused elsewhere.

### 2.6 Callback Pass-Through Chain

**Scope:** Watch

`onRecentActivityDayLimitChange` passes through:

1. RecentActivityView
2. MilestoneGoalRowView
3. FinalGoalDetailView
4. GoalListView
5. MilestoneGoalStore.ensureRecentActivityDayLimit

**Recommendation:** This is normal SwiftUI unidirectional flow. Revisit only if more layout-driven callbacks appear. An environment object would shorten the chain but also make dependencies less explicit.

---

## 3. Efficiency

### 3.1 Width Growth Triggers Full Milestone Refresh

**Scope:** Introduced

**MilestoneGoalStore.swift:39-43**

`ensureRecentActivityDayLimit()` only refreshes when the requested limit grows:

```swift
guard dayLimit > recentActivityDayLimit else { return }
recentActivityDayLimit = dayLimit
refresh(finalGoalID: finalGoalID, day: day)
```

So this is not a refresh on every resize event. However, when the limit does grow, a layout measurement from one row can trigger a full refresh of all milestones for the selected final goal, including completion lookups and recent activity reconstruction.

**Recommendation:** Keep this as the top performance follow-up. Options:

- Debounce or coalesce day-limit growth before refreshing.
- Store the max observed required limit per selected final goal and refresh once.
- Fetch only the additional activity range instead of rebuilding all milestone snapshots.

### 3.2 All Completions Fetched for Recent Activity

**Scope:** Worsened

**MilestoneGoalRepository.swift:239-245**

```swift
let completedDayKeys = Set(try fetchCompletions(goalID: goalID).map(\.dayKey))
```

This existed before as a 30-day activity view, but the branch makes the day count width-responsive and potentially larger. Fetching all completions for each milestone becomes more important as goals accumulate history.

**Recommendation:** Filter completions by the requested date range at the database level, or add a repository method that fetches only completions between the computed start and end day keys.

### 3.3 availableWidth State Updates on Every Preference Change

**Scope:** Introduced

**RecentActivityView.swift:38-47**

```swift
.onPreferenceChange(RecentActivityWidthKey.self) { width in
    availableWidth = width
    let newLimit = ...
    guard newLimit != lastEmittedDayLimit else { return }
    ...
}
```

The callback is guarded by `lastEmittedDayLimit`, but `availableWidth` is still assigned first.

**Recommendation:** Only assign when the measured width actually changed:

```swift
if availableWidth != width {
    availableWidth = width
}
```

Keep `visibleDayCount` derived from `availableWidth`; do not derive UI visibility from `lastEmittedDayLimit`, because that would mix layout state with fetch/debounce state.

### 3.4 Redundant GeometryReader in Same Row

**Scope:** Watch

GoalRowView and RecentActivityView each measure width independently:

- `TitleRowWidthKey` measures the title row.
- `RecentActivityWidthKey` measures the activity row.

**Recommendation:** Do not optimize this first. The better fix is likely to remove the title/tag width workaround in 2.1. After that, re-check whether both measurements are still necessary.

### 3.5 Fetch-All-Then-Filter in Widget

**Scope:** Pre-existing / Slightly worsened

**MilestoneGoalRepository.swift:147-172**

```swift
let activeFinalGoals = try fetchFinalGoals().filter(\.isActive)
let activeMilestones = try fetchMilestones(for: finalGoal.id)
    .filter { $0.isActive && $0.completedAt == nil }
```

The branch changes widget semantics from "current milestone" to "all active milestones", so it may increase the number of milestones considered. But fetch-all-then-filter is an existing repository style.

**Recommendation:** Track separately from the layout follow-up. Use `FetchDescriptor` predicates when widget performance becomes measurable or when repository query cleanup is already planned.

### 3.6 activity.suffix(visibleDayCount) Creates an ArraySlice Each Render

**Scope:** Nit

**RecentActivityView.swift:22**

This is lightweight and unlikely to matter compared with database fetching and view refresh behavior.

**Recommendation:** Remove from the active priority list unless profiling points here.

### 3.7 Widget Timeline Reload on Every Mutating Operation

**Scope:** Pre-existing

`refreshAndReloadWidget()` reloads widget timelines after create, update, complete, uncomplete, delete, and `setMilestoneActive`.

**Recommendation:** This is broader than the branch. Consider debouncing or checking widget-relevant changes later, but do not bundle it with the recent-activity width cleanup.

---

## Summary

| Category | High Priority | Medium Priority | Low / Watch |
|----------|:---:|:---:|:---:|
| Reuse | — | — | Duplicate PreferenceKey (1.1), width validation (1.2), clamp utility (1.3), refresh helper (1.4) |
| Quality | Manual title/tag width layout (2.1) | Layout helpers under `RecentActivityLayout` (2.2) | Ternary (2.3), guard readability (2.4), row parameter count (2.5), callback chain (2.6) |
| Efficiency | Width growth triggers full refresh (3.1), range-limit recent activity completion fetches (3.2) | Guard repeated width state writes (3.3) | GeometryReader dedup (3.4), widget fetch predicates (3.5), suffix slice (3.6), widget reload debounce (3.7) |

### Recommended Priority

1. **3.1** — Coalesce or narrow refreshes when responsive width requires a larger activity range.
2. **2.1** — Replace manual title/tag width math with resilient SwiftUI layout.
3. **3.2** — Fetch recent-activity completions by date range instead of loading all completions.
4. **2.2** — Move recent-activity layout helpers under `RecentActivityLayout` and update tests.
5. **3.3** — Avoid assigning `availableWidth` when the measured value did not change.

### Explicitly Deprioritized

- Shared `PreferenceKey` extraction: too little payoff right now.
- `MilestoneActions` callback grouping: wait until the row interface grows again.
- Widget reload debouncing and widget query predicates: valid, but broader than this branch.
- `activity.suffix(...)` optimization: not worth acting on without profiling evidence.
