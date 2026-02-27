# Task 2 Evidence: bootstrap.sh bd→br replacement

## Changes Made

### 1. Added `ensure_br_binary()` function (new lines 206-246)

- Inserted after `ensure_sem_binary()` (which ends at line 204)
- Direct tarball install from GitHub releases (v0.1.20)
- Follows same pattern as other ensure\_\*\_binary functions: check BIN_DIR → check system → download
- Supports Darwin/Linux × amd64/arm64

### 2. Replaced bd install in `ensure_extra_tools()` (line 249)

- **Before**: `ensure_go_binary bd github.com/steveyegge/beads/cmd/bd 0`
- **After**: `ensure_br_binary`
- bv line (line 250) unchanged — still uses `ensure_go_binary`

### 3. Replaced bd in `init_beads()` (line 337)

- **Before**: `"$BIN_DIR/bd" init -q`
- **After**: `"$BIN_DIR/br" init`
- Dropped `-q` flag as specified
- Guard condition (`config.yaml` check) unchanged

### 4. Replaced bd in `verify_installs()` tools array (line 383)

- **Before**: `local tools=(mise go bun uv openspec bd bv entire jj trunk linctl sem sg ast-grep)`
- **After**: `local tools=(mise go bun uv openspec br bv entire jj trunk linctl sem sg ast-grep)`

## Validation Results

### Syntax check

```
$ bash -n bootstrap.sh
SYNTAX CHECK: PASS (exit 0)
```

### Remaining bd references

```
$ grep -n '\bbd\b' bootstrap.sh
GREP EXIT CODE: 1
```

Exit code 1 = 0 matches. No `bd` references remain.

### Diff summary

- File grew from 384 lines to 426 lines (+42 net: the ensure_br_binary function)
- 4 change hunks, all matching expected modifications
- No unrelated changes
