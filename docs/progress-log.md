# CTDC-nx progress log

Newest first. One entry per session, with evidence: what broke, the cause, the fix.

## 2026-11-03: switch-test1 did not start; switch-test2

- switch-test1 stopped before the game: the launcher printed its usage and returned 2
  ("unknown option: crazytaxi_report.txt"). Cause: switch_main.cpp inserted `--report` at a
  fixed index 7, which with Crazy Taxi's argument list fell between `--vmu` and its file name.
  Fix: append it. Claude's porting bug, not a runtime problem.
- switch-test2: 3 build steps, sha256
  6bd6f8b08c4b273fa657573b482a9694a3616fefc1739ac2044ca69bc9dbe880. Its first delivery never
  reached the PC (the bridge kept test1's file while reporting it written), so Mark's second run
  was test1 again: the same log. Re-sent under a new name and verified by hash on the PC.

## 2026-11-03: Switch layer, first NRO (switch-test1)

- Switch toolchain: ghcr.io/danfromtico/switch-dev-legacy-vulkan run under docker in the cloud,
  in place of SA-nx's Wine copy of devkitPro. Had everything: devkitA64 15.2, libnx, SDL2, NVK.
- SA-nx's `switch/src/switch_main.cpp` and `egl_stubs.c` ported: SD folder
  `sdmc:/switch/crazytaxi/`, names, a plain CTDC icon (no Sega art). Sonic's `--idle-skip` and
  `--play-modules` removed. Patch 0025 moves dream-recomp's own SD paths (options, bindings,
  pipeline cache) to the crazytaxi folder.
- switch-test1: 89 build steps, NRO 19,270,612 bytes, sha256
  385144e70d192089544583ac38d62cefcff0ff0879ac9f3514a8823a21182316. Development build: first run
  writes CPU_MHZ=1785, profiler and end-of-run report on.

## 2026-11-03: play test 2, smooth; ready for the Switch

- Low-latency pacing: 59.4 to 59.9 fps shown in play at 0.97x to 1.00x, every rendered frame
  presented. Mark: "felt great". Lowest five seconds: 56.7 fps at 0.94x, with the game thread at
  74% plus 15% sound and no sleep left. The Switch will need SA-nx's speed work (sound thread,
  idle skip, translator options).
- Mark: coverage testing (all modes) on the Switch rather than on PC.
- Trigger ramp off by default (patch 0024, Mark's call): a digital trigger is fully down at once.
  Still a row in the controls menu. Analogue triggers were never ramped.
- Config: the last two run-time copies and the entry 0x20 into the 0x8C00FA00 stub.

## 2026-11-03: play test 1, the speed is there, the frames are not shown

- Play test with the seeds and stubs from the boot test: 483 guest s in 485 s of wall time
  (full speed; the report rounds it down to 0.9x). Untranslated calls 291,383 down to 2, the
  audio stretcher padding 0.3% of the sound instead of 11%.
- The game thread has room: 13.5% of its samples asleep in pacing (ZwDelayExecution).
- Why it still did not look smooth: 27,887 frames drawn, 16,713 presented. The game draws about
  58 a second, the window showed about 35. SA-nx's "smooth" pacing (patch 0022, options.pacing 0)
  leaves the last finished frame up whenever the render thread is still drawing; for a 60 fps
  game that drops about four frames in ten, unevenly.
- Change, scripts only (no rebuild): play and boot test pass `--options` with a per-game options
  file created as PACING=latency plus SHOW_FPS=1, and `--perf-log` for five-second timing lines.
- For the Switch later: `fn_0c1582a0` (the wait loop sp00nznet's recomp hangs in) is 9.5% of
  the game thread, and C++ unwinding (`_NLG_Return2`) 15%: an idle skip candidate, like SA1's.
- Left for the next build: relocation 0x0C0D2C6C (0x1D8) -> 0x8C00EE3C from suggested.toml, and
  0x8C00FA20 (an entry inside the 0x8C00FA00 stub), each reached once.

## 2026-11-03: first boot test, playable

- First PC build and boot test (120 guest s): boots straight through to gameplay, Mark played a
  round. Sound on (421 key-ons), memory card works, 6,149 frames rendered, no crashes.
- Speed 0.8x real time overall on Mark's PC, and the audio stretcher padded 672,623 frames, so it
  ran slow. He wants it smooth.
- Cause found in the report: 291,383 calls went to untranslated code and ran in the interpreter.
  0x0C081476 alone 181,621 times; the interrupt stubs at VBR 0x8C00F400 (+0x600 at 0x8C00FA00)
  47,181 times each, once per interrupt.
- Fix: the 8 suggested seeds into [functions], the 4 VBR stubs as no_fold relocations, and the 9
  other run-time copies the run matched byte for byte.
- Seen, not acted on: SA-nx's 0x8C900000 module check (patch 0022) reads Crazy Taxi as
  "gameplay" (0x8C900000 starts FFFFF418), which only switches the translucency mode to the
  menu's choice. Rework it for Crazy Taxi in the Switch phase.

## 2026-11-03: kickoff

- Chose Crazy Taxi, then Crazy Taxi 2, as the next Dreamcast ports after SA-nx. Mark owns both
  USA discs (CHDs in `assets/`).
- Read both CHDs through dcdisc with libchdr built on the bridge. Both V1.004, USA, not Windows CE.
  Every hunk decompressed with libchdr's checks passing. Track SHA-1s are in `CLAUDE.md`.
- Extracted both discs into `games/<id>/extracted/` with `tools/extract_resumable.py` (one pass
  each). Crazy Taxi: 51 files. Crazy Taxi 2: 167 files.
- `dcdisc scan` on every Crazy Taxi file: SH-4 code only in `1ST_READ.BIN` (3,997 rts, literal
  pool pointer ratio 0.87). No overlays configured.
- Repo set up from SA-nx: patches 0001 to 0023 carried over (they apply cleanly, in order, to
  dream-recomp 51a148c), PC scripts adapted (`-Game`, 8 translation parts for a 1.4 MB binary,
  no Sonic intro hiding).
- Prior art: sp00nznet/crazytaxi (dcrecomp, MIT) boots this disc but never draws a frame: it
  stays in an init wait loop at `impl_8C1582AE`. Reference only; nothing taken from it.
- Next: Mark's first PC build and boot test. Its purpose is to see how far the translator gets on
  Hitmaker's code, not to show gameplay.
