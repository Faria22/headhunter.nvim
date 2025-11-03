# Conflict Refresh & Quickfix Sync Plan

- Add a helper that recomputes conflicts via `M._get_conflicts()`, refreshes the module-level `conflicts` cache, and clamps `current_index` so navigation skips resolved hunks.
- Call the helper at the end of `apply_resolution` so the next navigation command lands on the next unresolved conflict.
- Track whether `M.populate_quickfix` seeded the quickfix list (for example with a `quickfix_active` flag) and, when conflicts are refreshed, rebuild the quickfix entries using `build_quickfix_entries` only when the flag is set; clear or close the list when no conflicts remain.
- Emit a short status message when the quickfix list or navigation pool becomes empty to match existing UX.
- Update `README.md` to mention that quickfix entries now stay in sync with the resolved conflicts.
