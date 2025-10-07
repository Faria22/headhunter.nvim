#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$ROOT_DIR/repo"

if [[ -d "$REPO_DIR" ]]; then
    echo "Removing existing demo repo at $REPO_DIR" >&2
    rm -rf "$REPO_DIR"
fi

mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

git init -q -b main

cat <<'LUA' > app.lua
local function greet(name)
    return "hello " .. name
end

return greet
LUA

cat <<'LUA' > service.lua
local M = {}

function M.lookup(user)
    return "user:" .. user
end

return M
LUA

git add app.lua service.lua
git commit -q -m "chore: initial state"

git checkout -q -b feature

cat <<'LUA' > app.lua
local function greet(name)
    return "hello " .. name .. "!"
end

return greet
LUA

cat <<'LUA' > service.lua
local M = {}

function M.lookup(user)
    return "account:" .. user
end

return M
LUA

git commit -am "feat: add excitement" -q

git checkout -q main

cat <<'LUA' > app.lua
local function greet(name)
    return "hi " .. name
end

return greet
LUA

cat <<'LUA' > service.lua
local M = {}

function M.lookup(user)
    return string.upper(user)
end

return M
LUA

git commit -am "feat: change messaging" -q

if git merge feature >merge.log 2>&1; then
    echo "Expected merge conflict but merge completed successfully" >&2
    cat merge.log >&2
    exit 1
fi

rm -f merge.log

echo "Demo repo ready at $REPO_DIR"
echo "Conflicted files:"
echo "  - app.lua"
echo "  - service.lua"
