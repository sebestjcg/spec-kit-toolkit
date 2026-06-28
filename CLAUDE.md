# spec-kit-toolkit — Development Notes

## Installing specify CLI

`specify` is not pre-installed in this environment. Install it with:

```bash
# 1. Install uv (if missing)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Install specify-cli — check https://github.com/github/spec-kit/releases for the latest tag
~/.local/bin/uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.11.9

# 3. Add to PATH for the session
export PATH="$HOME/.local/bin:$PATH"
```

`specify` lands at `~/.local/bin/specify`. Always use `export PATH=...` or the full path — `~/.local/bin` is not on the default shell PATH here.

## Git Worktrees

Always create worktrees with a **relative path** so the worktree is portable across machines and IDEs (e.g. PyCharm resolves the repo from `/home/sebestjcg/PycharmProjects/github/spec-kit-toolkit`, not `/workspace/spec-kit-toolkit`):

```bash
# Good — relative path, works everywhere
git worktree add ../.claude/worktrees/my-branch my-branch

# Bad — absolute path, breaks in PyCharm
git worktree add /workspace/spec-kit-toolkit/.claude/worktrees/my-branch my-branch
```

## Packaging

`scripts/package.sh` builds distributable zips for all presets and extensions and optionally cuts a GitHub Release. Requires `specify`, `python3`, and (for releases) `gh`. Run with `--no-release` to build zips only:

```bash
scripts/package.sh --no-release
```
