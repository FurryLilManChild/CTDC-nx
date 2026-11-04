# CTDC-nx progress log

Newest first. One entry per session, with evidence: what broke, the cause, the fix.

## 2026-11-04: switch-test6 full speed at 1785 MHz; menu crash; switch-test7

- switch-test6 at 1785 MHz: 58.8 to 60.1 fps shown at 0.98x to 1.00x through most of play
  (two dips: 0.85x and 0.68x). Mark: "pretty much full speed". Stock (1020 MHz this run): 36 to
  45 fps, 0.63x to 0.75x. GPU 1.7 to 1.9 ms a render; render thread 30 to 42% busy.
- Crash after closing the port menu (CPU set back to 1785) and opening it again at once: data
  abort (far 0x60) in Mesa's end_subpass under vk_common_CmdEndRenderPass2 (test6 ELF, module
  +0x1129244). Cause: the no-wait decision is made at the top of present(), but the menu opens
  later in the same present (pump_menu), and a menu composites through the CPU path, reading
  the offscreen target while its render was still on the render thread.
- Patch 0028: after pump_menu, a present that skipped the wait waits if a menu is open or the
  game is paused. Pipeline-cache saves, screenshots and captures wait for the render first too.
- switch-test7: 79 steps, sha256 583837eded4306e8bb568679892e969014d3873b22edf51d48e4e46ecd2b245b,
  renderer in, verified on Mark's PC.

## 2026-11-04: switch-test5 results; switch-test6

- switch-test5: the idle skip works, skipping 46 to 76% of guest time in play (about half).
  GPU and memory at stock from just before play; CPU 1785, then stock (1428 on Mark's console),
  then 1785. Play: 29 to 55 fps, 0.48x to 0.93x. The first 1785 stretch was the slowest, which
  the clocks do not explain (same clocks as the last, fastest one); probably what was on screen.
- test5 profile (51,644 samples below 0.95x): condition-variable wait 29.5% (the low-latency
  wait for the render thread at VBlank, render thread itself about 30% busy, GPU 1.2 to 1.5 ms a
  render); SD card reads through fread from the CHD reader about 6% (svcSendSyncRequest under
  fsdev_read) plus CHD hunk decompression, both on the game thread; swapchain IPC about 2.5%.
- Patch 0027:
  - no-wait present: with menus closed and the GPU present path, a refresh does not wait for
    the render in flight; the window's GPU copy shows the newest submitted frame. Every frame is
    shown once, one refresh late. Waits as before in menus, on the CPU present path, after a
    render-target switch, or with the CTDC_WAIT environment variable. Logged as "pacing: N
    refreshes did not wait for the render in flight".
  - a mutex on the Vulkan queue around every vkQueueSubmit, vkQueuePresentKHR, vkQueueWaitIdle
    and vkDeviceWaitIdle: render thread and game thread can now both submit.
  - CHD reader: hunks read and decompressed by a worker thread, 24 hunks ahead, 2,048 kept;
    the game thread only copies sectors (and waits when the worker is behind). Pinned to core 2
    through `dream::gdrom::on_worker_thread` ("disc").
- switch-test6: 80 steps, sha256 9ff91c750eb9f7b467bae231c22e8089a928c751105caa360640283e11413a66,
  renderer in, verified on Mark's PC.

## 2026-11-04: switch-test5, low latency only and the wait-loop skip

- Patch 0026: frame pacing fixed at low latency (Mark: a 60 fps arcade game shows every frame;
  no smooth option). The port menu row is hidden, an options file cannot turn smooth back on,
  and the menu banner reads CRAZY TAXI.
- `--idle-skip 0x0C156C30:0x0C158400,0x0C158440` in the Switch launcher and the PC scripts:
  the empty function the wait loop calls, from its two call sites (return address = jsr + 4).
  `enable_idle_skip` refuses anything that is not `rts; nop`, so a wrong address stops at start.
- switch-test5: 79 steps, sha256 484e38ca662362b28cb733a27173313a903e3a5ed8834aae8f007634f70dcd5e,
  renderer in, verified on Mark's PC. toml unchanged from test4.

## 2026-11-04: switch-test4 boots and plays, slow

- Boots to gameplay on the Switch, CPU 1785 MHz the whole run (stock not tried). Mark: low
  latency looked much better than smooth; for this game there must be no smooth option.
- Smooth stretch: about 21 fps shown of 42 rendered, 0.64x to 0.79x. Low latency: 34 to 39 fps
  shown, every render shown, 0.56x to 0.65x, with the game thread waiting for the render thread
  17 to 20% of the time. Sound thread 20 to 30% of core 2, render thread about 25% of core 0.
- Profile (56,361 samples below 0.95x, test4 ELF):
  - about a third of the game thread inside `fn_0c1582a0`, the game's wait loop at 0x0C1583F8,
    which calls the empty function 0x0C156C30 (`rts; nop`) through a pointer until an interrupt
    clears a flag. Idle skip candidate: `--idle-skip 0x0C156C30:0x0C158400,0x0C158440`.
  - about 18% waiting on a condition variable (svcWaitProcessWideKeyAtomic): the low-latency
    wait for the render thread at VBlank.
  - the rest spread over guest memory access (gld 9.5%, fast_area 5.8%), call_indirect,
    take_entry_pr and TLS reads (__aarch64_read_tp 4%).

## 2026-11-03: switch-test3 ran and faulted at once; switch-test4

- switch-test3, the first Switch build with the renderer: the launcher, NVK (Tegra X1 GM20B),
  the sound thread and the clocks all came up, then the game faulted after 0.016 guest s
  (3.1M cycles, no interrupts yet): a call to 0x00000000 from 0x0C00FA40, inside the
  0x8C00FA00 interrupt stub.
- That stub was changed after the last PC test (`entries = [0x8C00FA00, 0x8C00FA20]`), along
  with two new copied-code relocations, and none of it was ever run on PC. Not proven which of
  the three, but they are the only difference from play test 2's config, which boots and plays.
- switch-test4: crazytaxi.toml back to play test 2's (commit 4c037da). NRO sha256
  402523a893baa634ecd2f19c23317bc8964f4566cb2c96f00160b8ba5c0a0134, toml
  871af52d39fd214a426f1e2183c776510b8d3fe693384db2be3e2c04cb5c1e6a, both verified on the PC.

## 2026-11-03: switch-test2 had no renderer; switch-test3

- switch-test2 started the launcher with the right arguments, then stopped: "this build has no
  renderer". The toolchain image has no glslc (the build machine's shader compiler), and
  dream-recomp's CMake leaves the renderer out without one instead of failing.
- Fix: `switch/docker_build.sh` builds a local image with Debian's glslc on top (once), and
  `switch/build.sh` refuses to build when glslc is missing or the renderer is off. It also starts
  dockerd when the cloud machine has stopped it.
- switch-test3: 56 steps, NRO 34,053,076 bytes (test1 and 2 were 19 MB: no renderer), sha256
  093ff0a8d3cca39eb3a8ffeb74477343530b23ecdb5e54474ac38add8f3dcb3c, verified on Mark's PC.

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
