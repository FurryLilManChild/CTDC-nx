# CTDC-nx: notes for Claude

Native ports of **Crazy Taxi** (Dreamcast, USA, MK-51035 V1.004) and **Crazy Taxi 2** (Dreamcast,
USA, MK-51136 V1.004) built with [dream-recomp](https://github.com/phobos665/dream-recomp) static
recompilation. PC first, then Nintendo Switch homebrew (libnx). Crazy Taxi first, then Crazy
Taxi 2 on the same engine. Owner: Mark (GitHub FurryLilManChild). Load `switch-port-base` and
`dreamcast-switch-port` before working here. Reference port: SA-nx (Sonic Adventure).

The name is CTDC-nx, not ct-nx: a Switch port of the Android Crazy Taxi already exists, and this
is the Dreamcast version (original soundtrack and all). Keep the name everywhere.

## Who does what

- Claude writes all code, scripts and configs, reads logs, and commits.
- Mark runs the PowerShell scripts on his Windows PC, boot tests and play tests, and moves Switch
  builds to the SD card himself. He writes no code.
- Claude reaches `C:\CTDC-nx` through the device bridge (a Linux shell with the folder mounted at
  `$HOME/mnt/CTDC-nx`). That shell cannot run Windows programs, cannot delete files there, and
  stops anything still running when each call returns (about 3 minutes per call).
- PC builds run on Mark's PC, never in the cloud unless he agrees first. Switch NRO builds in the
  cloud are fine.

## Hard rules

- Never use em dashes anywhere (chat, docs, commits). No decorative emoji.
- Never commit game data: `assets/`, `games/*/extracted/`, saves, captures. Run `git status`
  before every commit.
- Commit as `FurryLilManChild <346934328+FurryLilManChild@users.noreply.github.com>`.
- dream-recomp stays pinned in the `dream-recomp` submodule. Our changes to it go in
  `patches/dream-recomp/*.patch`, applied as one set by the build scripts. 0001 to 0023 came over
  from SA-nx unchanged (0022 is SA-nx's Switch rolling patch: its Sonic-specific bits, SD paths
  and the 0x8C900000 module check, get reworked in the Switch phase). Follow dream-recomp's own
  rules (its `.claude/skills/dream-recomp`): never paste Sega SDK text, every emitter change gets a
  differential test.

## Upstreams and licences

| Upstream | Use | Licence |
|---|---|---|
| phobos665/dream-recomp @ 51a148c | recompiler, runtime, renderer, disc tools | GPL-2.0 |
| FurryLilManChild/SA-nx | patch set, scripts, Switch layer | GPL-2.0 |
| sp00nznet/crazytaxi (dcrecomp) | reference only: a separate recomp of the same disc that stops in an init wait loop (`impl_8C1582AE`, from `func_8C148962` via `func_8C02A698`, `func_8C0296FE`) | MIT |
| libsdl-org/SDL 3.4.16 (VC package) | window, input, audio on PC | zlib |

This repository is GPL-2.0 (dream-recomp's licence), see `COPYING`.

## Layout

```
dream-recomp/          submodule, pinned
games/crazytaxi/       crazytaxi.toml (config, committed), CMakeLists.txt, extracted/ (ignored)
games/crazytaxi2/      extracted/ only for now (ignored); configured after Crazy Taxi plays
assets/                Mark's CHDs (ignored)
tools/extract_resumable.py   disc extraction in passes (the bridge's time limit)
tools/win/             setup_pc, build_pc, boot_test, play, trace_run (-Game crazytaxi2 later)
docs/progress-log.md   newest first, one entry per session with evidence
```

## The loop (PC phase)

1. Claude changes config or code, commits, pushes.
2. Mark runs, always given in exactly this form (his PowerShell blocks bare `.ps1` scripts):
   ```
   git pull
   powershell -ExecutionPolicy Bypass -File tools\win\build_pc.ps1
   powershell -ExecutionPolicy Bypass -File tools\win\boot_test.ps1
   ```
3. Claude reads `out\logs\*` through the bridge (boot.log, boot-report.txt, suggested.toml),
   merges suggested seeds into the toml with evidence in the progress log, presents findings and
   the next plan, and waits for Mark's go-ahead.

## Reading CHDs from the bridge

The bridge's Linux shell has no chdman. dream-recomp's `dcdisc` reads CHDs through libchdr: build
`third_party/libchdr/unity.c` plus `src/libchdr_codec_avhuff.c` into a shared library with gcc and
point `DCDISC_LIBCHDR` at it (2026-11-03; the bridge workspace is wiped between sessions).

## Disc facts

| | Crazy Taxi | Crazy Taxi 2 |
|---|---|---|
| Product | MK-51035 V1.004 (1999-12-19) | MK-51136 V1.004 (2001-05-02) |
| CHD SHA-1 | a6d60321bb33d541edb6611516f92ccc095608af | 348a032208d610d572b89825d047e8f94646fea9 |
| Track 1 SHA-1 | cf38f6c262f304729870f443fce69ffd182214e1 | 15de448964d684e0bc51dbed8470eb15b811a687 |
| Track 2 SHA-1 | a3705cb0ce53c7adf906c5af76887406984de6a9 | a3705cb0ce53c7adf906c5af76887406984de6a9 |
| Track 3 SHA-1 | 082c341f140904b9a63b984c2dce1ea276f7afdb | 858ab545521727433d9e15cb44eb677f1afcfdb4 |
| Files | 51, 101 MB | 167, 153 MB |
| 1ST_READ.BIN | 1,468,208 bytes, plain, SHA-1 8b5bd2a2380799e4e1de46cf801c352fd90c2f3e | 1,452,148 bytes, plain, SHA-1 bcff06e9defcd454d99ada84b9d26757e8ab4221 |

- Track hashes are of the raw 2352-byte sectors as dcdisc reads them (audio byte-swapped back to
  little-endian). Not yet checked against Redump (its site refuses automated reads).
- Both are Katana SDK titles (Shinobi, Kamui, ADX banners), not Windows CE.
- Crazy Taxi: no code outside 1ST_READ.BIN, no movies.
- Crazy Taxi 2: same file families as Crazy Taxi, plus `SG_DPLDR.BIN`, `2_DP.BIN` and `DP*`
  folders, probably a bundled Dream Passport browser for its online features (unconfirmed).
