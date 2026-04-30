# Data Schema and Migration Policy

## Current Schema

### FinalGoal

Stored as a SwiftData `@Model` in `Packages/OneStepCore/Sources/OneStepCore/Models/FinalGoal.swift`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | `@Attribute(.unique)`. Stable identifier. Never reused. |
| `title` | String | Non-empty after trim. User-editable. |
| `goalDescription` | String? | Optional longer description. `nil` when unset. |
| `targetCalendarDays` | Int? | Optional deadline in calendar days from creation. `nil` means no deadline. |
| `startDayKey` | String | YYYY-MM-DD format. Set on creation. |
| `sortOrder` | Int | Manual ordering. Defaults to creation order (incrementing). |
| `archivedAt` | Date? | `nil` when active. Set when complete, ended, or archived. |
| `createdAt` | Date | Set once on creation. |
| `updatedAt` | Date | Updated on every mutation. |

`FinalGoal` stores the long-term aspiration. Its only lifecycle status field is `archivedAt`; setting it means the goal is complete/ended/archived and should not appear in active workflows.

Computed: `isActive = archivedAt == nil`.

### MilestoneGoal

Stored as a SwiftData `@Model` in `Packages/OneStepCore/Sources/OneStepCore/Models/MilestoneGoal.swift`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | `@Attribute(.unique)`. Stable identifier. Never reused. |
| `title` | String | Non-empty after trim. User-editable. |
| `targetCompletionDays` | Int | Must be > 0. Represents intended completed days, not calendar duration. |
| `finalGoalID` | UUID | Foreign key to `FinalGoal.id`. |
| `sortOrder` | Int | Determines milestone sequence within a FinalGoal. |
| `startDayKey` | String? | YYYY-MM-DD format. Set on first check-in. `nil` until then. |
| `completedAt` | Date? | `nil` while in progress. Auto-set when `completedDays >= targetCompletionDays`. |
| `createdAt` | Date | Set once on creation. |
| `updatedAt` | Date | Updated on every mutation. |

`MilestoneGoal` stores one ordered phase under a final goal. Its only lifecycle status field is `completedAt`; it has no archive state.

Computed: `isActive = completedAt == nil`.

### DailyCompletion

Stored as a SwiftData `@Model` in `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Row identifier. |
| `goalID` | UUID | Foreign key to `MilestoneGoal.id`. |
| `dayKey` | String | YYYY-MM-DD format, normalized to the user's local calendar at completion time. |
| `completedAt` | Date | Actual timestamp of the completion event. |
| `uniqueKey` | String | `@Attribute(.unique)`. Computed as `"{goalID}#{dayKey}"`. Enforces one completion per milestone per day. |

## Storage Location

- App Group identifier: `group.dev.dynnfa.OneStep`
- Store path: `~/Library/Group Containers/group.dev.dynnfa.OneStep/OneStep/OneStep.sqlite`
- Both the app and Widget extension read and write the same store file.

## Data Invariants

1. **One completion per milestone per local day.** Enforced by the unique `uniqueKey` on `DailyCompletion`. Duplicate same-day writes are repository-level no-ops.
2. **Only the current active milestone can receive check-ins.** `MilestoneGoalRepository.completeToday` verifies the milestone is the first active milestone (ordered by `sortOrder`) within its parent FinalGoal.
3. **Check-in requires an active parent FinalGoal.** `completeToday` rejects if the parent FinalGoal is archived.
4. **Milestone auto-completes when target is reached.** `completedAt` is set automatically when `completedDays >= targetCompletionDays`.
5. **FinalGoal completion is archival.** Completing/ending a FinalGoal sets `archivedAt`; it does not mutate its milestones and does not require all milestones to be complete.
6. **Delete cascades.** Deleting a FinalGoal removes all its milestones and their completions. Deleting a MilestoneGoal removes its completions.
7. **Progress uses completion count, not elapsed days.** Progress = `completedDays / targetCompletionDays`.
8. **Target completion days cannot drop below completed count.** Enforced in `MilestoneGoalRepository.updateMilestoneGoal`.
9. **IDs are stable UUIDs.** Never reused or recycled.

## Migration Policy

### Before v1.0

Schema changes may be made deliberately. SwiftData's lightweight migration handles added fields with defaults. Breaking changes (renamed fields, removed fields, changed types) are acceptable because no public release depends on the current schema.

### After v1.0

- Schema changes require a migration note in this document.
- Lightweight additions (new optional fields, new models) are handled by SwiftData's automatic migration.
- Destructive changes (field removal, type changes, constraint changes) require a documented migration path and a manual backup/export mechanism before the migration ships.
- Every schema-affecting PR must update this file.

### Current Schema Version

The schema has no explicit version number yet. One will be assigned before the v1.0 public release tag.

## PR Checklist for Schema Changes

- [ ] Document the change in this file.
- [ ] Add or update unit tests covering the new or changed fields.
- [ ] If the change is destructive, add a backup/export path first.
- [ ] Verify that both the app and Widget can still read the store after the change.
