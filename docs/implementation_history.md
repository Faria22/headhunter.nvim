# Implementation History

This file summarizes the major headhunter.nvim iterations explored while debugging conflict navigation and resolution behaviour.

## 1. Auto-write Option (Current)

- Added `auto_write` (default `true`) to `setup()` so the plugin can automatically save the buffer after resolving a conflict while preserving backward compatibility.
- After `:HeadhunterTakeHead`, `:HeadhunterTakeOrigin`, or `:HeadhunterTakeBoth`, the buffer writes when `auto_write` is enabled; otherwise navigation warns and stops until the user saves manually.
- Introduced a lightweight `notify()` helper and configuration validation to surface errors when `auto_write` is not boolean.
- Specs now assert both behaviours: disk writes with `auto_write = true` and navigation warnings with `auto_write = false`.
- README documents the option and references the new demo sandbox in `demo/conflict_lab`.
- `demo/conflict_lab/setup.sh` builds a reproducible merge containing conflicts in `app.lua` and `service.lua` for hands-on testing.

## 2. Buffer-aware Conflict Detection (Previous Attempt)

- Replaced `vim.fn.readfile` with an in-memory reader so `_get_conflicts` reflected unsaved buffer edits.
- Updated navigation to switch buffers via `bufadd`/`bufload`, eliminating `:edit` prompts and the associated `E37` errors.
- Adjusted tests to stub `io.popen`, create temporary buffers, and confirm conflicts disappeared after resolving without saving.
- Added a headless Neovim script to manually validate buffer-aware conflict tracking.

## 3. Strict No-hidden Navigation (Intermediate)

- Added logic to temporarily enable `:set hidden` only when necessary, allowing navigation across modified buffers without forcing a save.
- Crafted tests ensuring navigation succeeded when `hidden` was `false` and that the option returned to its previous value afterward.
- Introduced user-facing warnings via `vim.notify` if navigation failed.

## 4. Original Behaviour (Baseline)

- `_get_conflicts` relied solely on on-disk files, so resolved-but-unsaved conflicts reappeared during navigation.
- `navigate_conflict` executed `vim.cmd("edit ...")`, causing "No write since last change" errors when buffers were dirty.
- `apply_resolution` replaced conflict text but left saving entirely to the user.

## Testing Notes

- `make test` has remained blocked across iterations because `scripts/minimal_init.lua` is not valid Lua and the macOS test environment prevents Neovim from creating swap files. Manual headless scripts were used where possible to validate changes.
