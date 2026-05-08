# One Step MVP QA Checklist

## Core Data

- [ ] Create a `Vocabulary` FinalGoal with a `Study 30 minutes / 200 days` milestone.
- [ ] Confirm completed count starts at `0`.
- [ ] Complete today in the app.
- [ ] Confirm completed count becomes `1`.
- [ ] Undo today in the app.
- [ ] Confirm completed count returns to `0`.
- [ ] Complete the same goal twice from Widget.
- [ ] Confirm completed count remains `1`.

## Validation

- [ ] Empty title is rejected.
- [ ] Empty milestone title is rejected.
- [ ] Target completion days `0` is rejected.
- [ ] Target completion days below completed count is rejected.

## Ordering

- [ ] Create 5 active goals, each with at least one incomplete milestone.
- [ ] Reorder goals in the app.
- [ ] Confirm Widget order follows app order after timeline reload.

## Archive

- [ ] Archive an active goal.
- [ ] Confirm it leaves the active section.
- [ ] Confirm it appears in archived history.
- [ ] Confirm it disappears from Widget data.
- [ ] Click a stale Widget row for the archived goal.
- [ ] Confirm no new completion is created.

## Widget Families

- [ ] Small Widget shows up to 2 milestones.
- [ ] Medium Widget shows up to 4 milestones.
- [ ] Large Widget shows up to 12 milestones.
- [ ] Widget rows do not clip badly with long final-goal or milestone titles.
- [ ] Completed Widget rows show the completed state.

## App Group and Logs

- [ ] App and Widget both use `group.dev.dynnfa.OneStep`.
- [ ] Widget reads a goal created by the app.
- [ ] App reads a completion created by the Widget.
- [ ] Console logs distinguish store, repository, Widget timeline, and AppIntent failures.
