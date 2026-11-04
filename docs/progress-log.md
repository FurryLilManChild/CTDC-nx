# CTDC-nx progress log

Newest first. One entry per session, with evidence: what broke, the cause, the fix.

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
