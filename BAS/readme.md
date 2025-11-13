# QUEST Adventure (QBASIC 4.5) — Normalized Build

This package contains:
- `quest_normalized.bas` — full source with **all GOTOs removed**, bug fixes, and inline `FIX:` comments.
- `quest_smoketest.bas` — a tiny test script to exercise **utility routines** (text wrapping, uppercasing, parsing) without needing `QDATA.dat`.
- (You must provide) `QDATA.dat` — the original random-access data file with **100-byte records**. The game expects 1-based record addressing when doing `GET #1, CurrentRecord + 1`.

## How to run

### Option A: MS-DOS / QBASIC 4.5
1. Copy `quest_normalized.bas` and your `QDATA.dat` into the same folder.
2. Launch `QBASIC.EXE` and open `quest_normalized.bas`.
3. Press `Shift+F5` (Run).

### Option B: DOSBox
1. Place `QBASIC.EXE`, `quest_normalized.bas`, and `QDATA.dat` in a folder (e.g., `C:\quest`).
2. In DOSBox:

