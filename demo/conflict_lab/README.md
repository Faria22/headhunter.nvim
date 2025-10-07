# Conflict Lab

This sandbox repository makes it easy to reproduce merge conflicts and try out
`headhunter.nvim`'s new `auto_write` toggle.

## Setup

```sh
./setup.sh
```

The script creates a `repo/` directory (ignored by Git) that contains a tiny
project stuck mid-merge with conflicts in both `app.lua` and `service.lua`.

## Workflow Ideas

1. Enter the repo and open Neovim: `cd repo && nvim app.lua`.
2. Run `:HeadhunterTakeHead` followed by `:HeadhunterNext` to confirm that the
   second conflict is reached immediately when `auto_write = true` (the default).
3. `:lua require('headhunter').setup({ auto_write = false })` (or toggle the
   option in your config), resolve the first conflict again, and check that
   Headhunter now warns until you `:write` manually.
4. Reset any time with `git reset --hard` or by rerunning `./setup.sh`.

Feel free to modify the repo to suit other experiments—the script can always
recreate the conflicted state from scratch.
