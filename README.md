# CTDC-nx

Native PC and Nintendo Switch ports of **Crazy Taxi** and **Crazy Taxi 2** for the Sega
Dreamcast, made by static recompilation with
[dream-recomp](https://github.com/phobos665/dream-recomp). This is the Dreamcast version,
original soundtrack included, not the mobile one.

## Status

Early work. Nothing is playable yet. Crazy Taxi comes first, then Crazy Taxi 2.

## You need

Your own USA disc of each game, as a CHD or GDI dump. No game data is included in this
repository or its releases.

| Game | Product | Track 3 SHA-1 (raw sectors) |
|---|---|---|
| Crazy Taxi (USA) | MK-51035 V1.004 | 082c341f140904b9a63b984c2dce1ea276f7afdb |
| Crazy Taxi 2 (USA) | MK-51136 V1.004 | 858ab545521727433d9e15cb44eb677f1afcfdb4 |

## Credits and licence

- dream-recomp by phobos665 (GPL-2.0): the recompiler, runtime and renderer.
- SA-nx: the patch set and port layer this builds on.
- Flycast, KallistiOS and dreamcast.wiki for hardware documentation, by way of dream-recomp.
- sp00nznet/crazytaxi for showing where a recompiled Crazy Taxi first stalls.

GPL-2.0, see `COPYING`. Crazy Taxi is a Sega game; this project is not affiliated with or
endorsed by Sega.
