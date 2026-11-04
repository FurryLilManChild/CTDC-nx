# CTDC-nx progress log

Newest first. One entry per session, with evidence: what broke, the cause, the fix.

## 2026-11-04: release 0.5.0 candidate

- Mark's calls: version 0.5.0, a fresh install starts at 1224 MHz (releases too), Switch only for
  now, and the dev interpreter stays in 0.5.0 for the two once-per-session untranslated spots
  (0xAC005990, a copied routine called through its uncached alias from 0x0C00456E; and
  0x8C00FA20, inside the interrupt stub, the spot that faulted in switch-test3 when given an
  entry and that dream-recomp's docs/crazytaxi-divergence.md leaves open). A deviation from
  dream-recomp's "no interpreter in release" rule, noted in the README's known issues.
- `RELEASE=1 ./switch/docker_build.sh`: CTDC_RELEASE (no report, no profiler, --quick-exit);
  only switch_main.cpp changes, 3 steps on top of a development build. CTDC_VERSION is now a plain
  CMake variable: as a cache entry the existing build directory kept 0.1.0 (caught by checking the
  NRO's strings before sending).
- Checked: renderer strings present, no profiler or report file name in the NRO, 0.5.0 in it,
  launcher arguments as in the coverage run plus --quick-exit.
- CTDC-nx-0.5.0.zip (switch/crazytaxi/: NRO, toml with SD paths, README.txt, COPYING.txt,
  disc/PUT_YOUR_DISC_HERE.txt), sha256
  e80f15d4bcde51e44d16bdfd9cebc120f7e6ee82b9dbab24ad53b49a7abb52b2; NRO 71,965,652 bytes, sha256
  6b56ac4a53c088896065a16a5f71a86dce7745d24745c0e8f831ea36433e8330. Both and release_notes.md in
  C:\CTDC-nx\out\release\, zip hash verified there. ELF kept as out/crazytaxi-switch-0.5.0.elf.
- README rewritten for the release. Next: clean-install test on Mark's Switch.

## 2026-11-04: coverage run 1 (switch-test10)

- Mark ran the full checklist (Arcade and Original with every rule, Crazy Box, Options, Save &
  Load, Records, idle title, port menu) in one launch: 386 s of guest time, 1224 MHz, later
  1581 MHz. Log: clean exit, no crash file.
- Report: untranslated call targets still only the two known ones (0x8c00fa20, 0xac005990);
  unmapped accesses 0; textures 2,149 decoded, 0 failed; audio 0 dropped blocks; memory card 222
  block reads and 400 block writes (the card was found formatted at start, i.e. kept from earlier
  runs). The candidate relocation 0x8c00ee3c (0x0C0D2C6C, 0x21C) is the one that faulted in
  test3 when added with entries; not added.
- 80 perf readings, 11 below 0.95x; the lowest (0.72x to 0.82x) have the game thread under 90%
  busy, so they are not CPU-bound play (loading or mode changes, not yet tied down).
- Only one launch in the logs (the previous log is test10's speed run), so the relaunch-and-load
  check is not in them.

## 2026-11-04: performance paused; coverage testing next

- Mark: move on to coverage testing (stock about 0.90x in heavy play, 1224 MHz about full
  speed). Development builds' first run now writes CPU_MHZ=1224 (was 1785); it applies only when
  crazytaxi_options.txt does not exist yet, so the current SD card keeps its saved setting.
- Coverage runs use switch-test10 (no new build). Not emulated, expected: Jump Pack vibration
  (the maple bus has no vibration device), Rally Wheel.
- Remaining stock candidates, if resumed: pair memory accesses as one check, single-precision
  FTRV, TA and store-queue path copies, present off the game thread.

## 2026-11-04: switch-test10 results

- Log matched to test10 by module size (0x4559000).
- Stock, stretches with the game thread at 86% or more (16 readings): 0.82x to 0.98x, about
  0.90x average. test9 was about 0.90x: no measurable gain from patch 0030.
- 1224 MHz (Mark's first run at this step): 0.96x to 1.00x, mostly 1.00x, game thread 76 to 93%
  busy. Mark: basically full speed.
- Profile, slow stretches, self time by guest function with inlined helpers counted in their
  function (tools: prof7.py and prof8.py in the scratch area): fn_0c081200 16.7% (test9) and 17.2%
  (test10) of slow samples, so its cost did not move. Inside it (test10): gst 22.7%, gld 20.6%,
  fast_area 13.3%, gld_pair 10.9%, ftrv_to 10.9%, its own code 12.5%. The loop is mostly guest
  memory access (vertex reads from RAM, pair stores into the store queue), not mode tests or FP
  register traffic. Next by function: fn_0c080e22 7.9%, fn_0c077af0 4.6%, svcSendSyncRequest
  4.1%, TA path (Ta::feed, resolve, sq_flush) about 9%.
- No crash.

## 2026-11-04: stock clocks, step 3 (switch-test10)

- Patch 0030, two translator changes, both on by default:
  - FP mode through delay-slot entries. A conditional branch into another branch's delay slot
    (the `_skip` path) gave the block after the slot no mode, so it and everything reached only
    through it stayed unknown. In Crazy Taxi that was the whole vertex loop (fn_0c081200: `bf` at
    0x0c081204 into the slot of the `bra` at 0x0c081206), so test9's copies of it still tested
    FPSCR at every FP instruction (33 tests per copy, now 3). The slot copy on that path is now
    also lowered in the entering mode: it used the owning branch's, which is wrong when the two
    differ (latent; not the case in Crazy Taxi, where both are the entry mode).
  - FR0..FR15 in host locals (EmitOptions::fp_locals, `--no-fp-locals`), written back and
    reloaded at the same points as the general registers plus FRCHG and FPSCR loads. Pair moves,
    DR arithmetic, FTRV, FIPR and FSCA work on the locals through helpers computing exactly what
    the Ctx versions do (ops.h). A body whose FP references are fewer than its write-back cost
    (calls and returns times the registers it names) goes back to the context. Crazy Taxi:
    1,228 bodies keep FP locals, the vertex loop's copies among them.
- Tests: new program p15_slotfp (hand-assembled: branch into a delay slot under two SZ modes).
  translator.fp_mode_copies now compares the default build against two variants (no copies, no
  FP locals) for p5, p7 and p15 in all four PR/SZ entry modes: 32 comparisons, all identical.
  Putting the old slot lowering back makes 4 of them differ. dream_emit_tests and the translator
  unit tests pass (dcdisc.pytest skips here: no pycdlib in the cloud workspace).
- Non-local returns (2.1% unwinding in test9's profile): the game's context restore
  (fn_0c0884ec, reached from fn_0c1708a0 and fn_0c17085e) throws on every task switch. The FDE
  cache already exists (switch_main.cpp); avoiding the throw needs another return path through
  every translated frame. Left out.
- switch-test10: NRO 71,977,940 bytes, sha256
  2b17c9233d4c721add2b6d5993d17535f98ac899db6625e932adc5a8e41a1a8f, verified on Mark's PC in
  out\sd\switch\test10 and copied over to out\sd\switch\crazytaxi. 3,906 copy bodies linked
  (fn_0c081200 all four), renderer strings present, launcher args unchanged. ELF kept as
  out/crazytaxi-switch-test10.elf. Build: 95 steps, 24 parts, no memory trouble.

## 2026-11-04: switch-test9 results

- Log matched to test9 by module size (0x4506000, about 72 MB).
- Stock (1020 MHz), stretches with the game thread at 89% or more (16 readings): 0.79x to 0.98x,
  about 0.90x average (test8 about 0.79x, test7 about 0.68x). Different parts of a round, so
  approximate; the lowest reading rose from 0.67x to 0.79x. Mark: gains felt.
- 1785 MHz: 1.00x throughout, game thread 51 to 69% busy (test8 68 to 78%).
- No crash; menu opened during play.
- Profile, slow stretches (16,165 samples, test9 ELF): the pr0sz0 copies are the ones running.
  Guest memory inline about 34%, TA and store-queue path about 11%, ftrv 4.1%,
  svcSendSyncRequest 4.4%, C++ exception unwinding (execute_cfa_program_generic,
  uw_update_context_1) 2.1%: non-local returns thrown during play. Thread-local reads
  (__aarch64_read_tp 1.9%, take_entry_pr 1.1%) and Memory::fast_view 1.7% also show.

## 2026-11-04: switch-test8 results

- Log matched to test8 by module size (0x244F000, about 38 MB); the previous log was test7
  (0x2130000).
- Stock (1020 MHz), stretches with the game thread at 90% or more: test7 0.63x to 0.75x (about
  0.68x average), test8 0.67x to 0.89x (about 0.79x average), about 15% faster (different parts
  of a round, so approximate). Early in the round test8 held 0.96x to 0.98x at stock.
- 1785 MHz: 1.00x with the game thread 68 to 78% busy; one dip to 0.67x.
- Port menu opened twice in play, no crash (test7's fix). The crash file in switchlogs is test6's.
- Profile, slow stretches (13,801 samples, test8 ELF): guest memory access inline (fast_area, gld,
  gst, gld_pair) about 36%, TA and store-queue path (Ta::feed, sq_flush, memcpy, resolve, find)
  about 10%, FP helpers (ftrv, get_dr, fmov_pair_store, sqrt) about 7%, svcSendSyncRequest 4.3%.
- .gitmodules: dream-recomp ignore = dirty (the build applies the patch set in the submodule tree).

## 2026-11-04: stock clocks, step 2 (switch-test9)

- Patch 0029, FP-mode copies (translator EmitOptions::fp_mode_copies, on by default,
  `--no-fp-mode-copies` to turn it off). A function whose entry FPSCR.PR or SZ is unknown (only
  reached through pointers, or callers disagree) tested that bit at every FP instruction (Crazy
  Taxi: 25,710 runtime branches). Such a body is now also emitted once per possible mode with the
  mode known, and the plain entry picks the copy once from FPSCR. Only bits the body actually
  tests are split. Resumes keep the generic body. Crazy Taxi: 1,192 functions copied (the vertex
  loop fn_0c081200 among them, 4 copies), generated C++ about 126 MB (45 MB before).
- Tests: dream_emit_tests and dream_translator_tests pass. New differential test
  translator.fp_mode_copies (tests/sh4/fp_mode_copies.py): p5_fpu and p7_fpuedge translated with
  and without copies, run from all four PR/SZ entry modes, final context and memory identical in
  all 8 runs (and the modes do give different results, so each copy is exercised).
- Expected gain at stock: a guess of 3 to 8%.
- First build: the assembler was killed for lack of memory on part 1 (8 parts, about 16 MB of C++
  each, two at a time in 7 GB). Rebuilt with 24 parts; build.sh now defaults to 24.
- switch-test9: NRO 71,637,972 bytes (test8: 37,333,972), sha256
  423b04c1700ee9cae54ef4a52bb92725a094d6bb308d9136f33fe9f530f9e1e1, verified on Mark's PC in
  out\sd\switch\test9 and copied over to out\sd\switch\crazytaxi. 3,906 copy bodies linked
  (fn_0c081200 has all four). Renderer strings present, launcher args unchanged. ELF kept as
  out/crazytaxi-switch-test9.elf. Risk: code size about doubled, which may cost instruction
  cache and eat into the gain.

## 2026-11-04: stock clocks, step 1 (switch-test8)

- test6 profile, slow stretches (12,588 samples, mostly stock): no wait left. Self time: guest
  memory access inline code (gld, fast_area, gst) about 28%, FP helpers about 11% (ftrv 7.6%,
  double-precision accumulation), the vertex loop fn_0c081200 itself about 23% of samples, TA
  and store-queue path about 8%, swapchain IPC on the game thread about 4%. Stack-walk inclusive
  numbers are unreliable for translated code (frames without records); self numbers are used.
- Stock (1020 MHz) ran 0.63x to 0.75x: needs about 35 to 45% less game-thread work.
- switch-test8: every translated unit at -O2 -fno-strict-aliasing (games/crazytaxi/CMakeLists.txt;
  dream-recomp builds them at -O1). SA-nx saw nothing from -O2; Crazy Taxi's hot code is an FP
  loop. NRO 37,333,972 bytes, sha256
  d817f4569daf5397b42fb24bc508ea860f02024acf7c521d990615c366020e08, verified on Mark's PC. Includes
  test7's menu fix.
- build.sh: re-apply the patch set when the submodule tree is clean even if the stamp matches
  (test8's first build ran on unpatched sources after a manual submodule reset and failed).
- Next candidate: FP registers in host locals (checklist item 4).

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
