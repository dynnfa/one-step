# Data Schema and Migration Policy

## Current Schema

### Goal

Stored as a SwiftData `@Model` in `Packages/OneStepCore/Sources/OneStepCore/Models/Goal.swift`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | `@Attribute(.unique)`. Stable identifier. Never reused. |
| `title` | String | Non-empty after trim. User-editable. |
| `dailyAction` | String | Non-empty after trim. User-editable. |
| `targetCompletionDays` | Int | Must be > 0. Represents intended completed days, not calendar duration. |
| `startDayKey` | String | YYYY-MM-DD format. Set on creation. Locked after first completion. |
| `sortOrder` | Int | Manual ordering. Defaults to creation order (incrementing). |
| `createdAt` | Date | Set once on creation. |
| `updatedAt` | Date | Updated on every mutation. |
| `archivedAt` | Date? | `nil` when active. Set when archived. |

### DailyCompletion

Stored as a SwiftData `@Model` in `Packages/OneStepCore/Sources/OneStepCore/Models/DailyCompletion.swift`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Row identifier. |
| `goalID` | UUID | Foreign key to `Goal.id`. |
| `dayKey` | String | YYYY-MM-DD format, normalized to the user's local calendar at completion time. |
| `completedAt` | Date | Actual timestamp of the completion event. |
| `uniqueKey` | String | `@Attribute(.unique)`. Computed as `"{goalID}#{dayKey}"`. Enforces one completion per goal per day. |

## Storage Location

- App Group identifier: `group.dev.dynnfa.OneStep`
- Store path: `~/Library/Group Containers/group.dev.dynnfa.OneStep/OneStep/OneStep.sqlite`
- Both the app and Widget extension read and write the same store file.

## Data Invariants

1. **One completion per goal per local day.** Enforced by the unique `uniqueKey` on `DailyCompletion`. Duplicate same-day writes are repository-level no-ops.
2. **Archived goals cannot be completed.** `GoalRepository.completeToday` checks `goal.isActive` before writing.
3. **Progress uses completion count, not elapsed days.** Progress = `completedDays / targetCompletionDays`.
4. **Target completion days cannot drop below completed count.** Enforced in `GoalRepository.updateGoal`.
5. **Goal IDs are stable UUIDs.** Never reused or recycled.

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
