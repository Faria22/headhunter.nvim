# Repository Guidelines

## Project Structure & Module Organization
- Core plugin lives in `lua/headhunter/init.lua`; keep feature modules local to this tree.
- Specs reside in `lua/tests/*_spec.lua`; mirror runtime modules when adding coverage.
- Shared test helpers and the headless Neovim bootstrap sit in `scripts/minimal_init.lua`.
- The `Makefile` exposes contributor-friendly commands; extend it when new workflows become common.

## Build, Test, and Development Commands
- `make test` runs all Plenary-busted specs using the bundled minimal Neovim config.
- `nvim --headless -u scripts/minimal_init.lua` is handy for ad-hoc Lua eval while mimicking CI.
- During manual QA, load the plugin via `:lua vim.opt.runtimepath:append('<path>/headhunter.nvim')` inside a Neovim instance.

## Coding Style & Naming Conventions
- Follow existing Lua style: 4-space indentation, snake_case identifiers, and descriptive local names.
- Group related helpers as local functions; expose only the documented module interface on `lua/headhunter/init.lua`'s return table.
- Prefer pure-Lua solutions and keep external shell calls guarded (see `M._get_conflicts`).

## Testing Guidelines
- Specs use plenary.nvim's Busted wrapper; new behaviour requires a matching `*_spec.lua`.
- Use focused describe/it blocks (`describe("quickfix", ...)` etc.) and stub Neovim APIs via `stub` from Plenary when side effects arise.
- Keep fixtures inline; favor deterministic buffers over filesystem writes.

## Commit & Pull Request Guidelines
- Commits observed in history mix imperative and topic prefixes (`feature: Handle ...`); stay concise and prefer present tense summaries under 72 chars.
- Squash WIP commits locally; each PR should read as a minimal change-set with clear intent.
- Pull requests should include: what changed, why it matters, test evidence (`make test` output or steps), and any merge-conflict scenarios covered.
- Link upstream issues when applicable and attach short demos (asciinema or gif) for UX-facing tweaks.

## Troubleshooting & Tips
- If tests fail with missing plugins, ensure `plenary.nvim` is installed or vendored in your Neovim config.
- Git conflict parsing relies on `git ls-files`; confirm the repository has staged conflicted files when debugging empty results.
