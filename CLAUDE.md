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

## Packaging

`scripts/package.sh` builds distributable zips for all presets and extensions and optionally cuts a GitHub Release. Requires `specify`, `python3`, and (for releases) `gh`. Run with `--no-release` to build zips only:

```bash
scripts/package.sh --no-release
```
