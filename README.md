# ioquake3 for LG webOS

[ioquake3](https://ioquake3.org), the Quake III Arena engine, built as a native webOS app (`com.pulp.quake3`). It comes with the Quake III Arena demo, so it plays after installing. Add your own game data for the full game. It was developed and tested on an LG C1 running webOS 6.5.3 (Mali-G51 GPU).

## Requirements

- **An ARMv8 CPU**, as in TVs with a 64-bit kernel such as the LG C1. The code is built for the Cortex-A55 in 32-bit mode, so it doesn't run on older ARMv7-only TVs.
- **OpenGL ES 3**, for the OpenGL2 renderer.
- **Root is not needed.** It installs from the Homebrew Channel or with `ares-install` in Developer Mode.

## Playing

- **The demo** is the official Quake III Arena demo (1.11) with its four maps. It ships in the app folder's `demoq3/` with id Software's license, `Q3A_EULA.txt`. The demo may be copied free of charge for non-commercial purposes as long as that license goes with it.
- **The full game:** copy your game's `baseq3` folder (`pak0.pk3` from the CD, Steam or GOG, plus the 1.32 point release's `pak1.pk3` to `pak8.pk3`) to a USB drive as `quake3/baseq3/`, then start the app. The game finds `quake3/baseq3/pak0.pk3` on any USB drive. Its config, saves and screenshots go into `quake3/home/` next to it, so they survive reinstalling the app.
- With no full game present, or when launched with `{"demo":true}` (`luna-send -n 1 luna://com.webos.applicationManager/launch '{"id":"com.pulp.quake3","params":{"demo":true}}'`), it plays the demo. The demo's config lives in the app folder.

**Controls.**

- **Remote:**
  - the arrows walk and turn;
  - OK shoots;
  - Back opens the menu.
- **Game controller** (see `app/gamepad.cfg`):
  - the left stick walks and the right stick looks;
  - R2/RT fires and L2/LT zooms;
  - the shoulder buttons change weapons;
  - Cross/A jumps and Circle/B crouches;
  - Options/Start opens the menu;
  - the D-pad and Cross/A drive the menus.
- **USB keyboard and mouse:** these work as on a PC.

The first start uses the TV's resolution, vsync and a 60 fps cap, and turns off the OpenGL2 renderer's costly extras (HDR, shadows, normal and specular maps) to keep 1080p smooth. When you press Home, the game mutes and slows down to 10 fps until you come back. The CD-key prompt is skipped: it is only a local check, and the full game still needs your own data. All single-player tiers are open from the start.

## How it works

- **Engine:** upstream ioquake3 at commit `52088b9e`, with `patches/ioq3-webos.patch`:
  - the gamepad works the menus;
  - text input, which brings up an on-screen keyboard only while the console or a chat line is open;
  - the remote's Back button maps to Escape;
  - no CD-key prompt;
  - `Sys_WebOSStart` in `code/sys/sys_main.c`.
- **`main` is the `ioquake3` binary itself.** The luna bus identifies an app by the executable named in `main`; with a wrapper script as `main`, the game cannot register and sits behind the launch spinner. So `Sys_WebOSStart` does a wrapper's work before `Com_Init`:
  - writes the log to `/tmp/quake3.log`;
  - sets `SDL_WEBOS_ACCESS_POLICY_KEYS_BACK`;
  - finds the game data or falls back to the demo;
  - sets the home path;
  - writes the first-start config, and appends `gamepad.cfg` and the webOS settings once (each marked by a file, so changes made in the menus stick);
  - skips the app manager's JSON argument.
- **Native game modules** (`cgame`, `qagame`, `ui` for `baseq3`, `missionpack` and `demoq3`) sit in the app folder; `vm_* 0` makes the engine use them. The demo's own QVMs are too old for this engine.
- **Rendering:** the OpenGL2 renderer on OpenGL ES (`r_preferOpenGLES 1`). Both renderers are built as loadable modules.
- **SDL:** webosbrew's [SDL 2.30.12 webOS port](https://github.com/webosbrew/SDL-webOS) (release `2.30.12-webos.1`, the build RetroArch ships), shipped as `lib/libSDL2-2.0.so.0` and found through the `$ORIGIN/lib` rpath. The TV's own SDL is 2.0.10.

## Build

On an x86-64 Linux machine with git, curl and Python 3:

```sh
./build.sh      # first run: fetches the openlgtv toolchain (2026.08-webos) and ioquake3, applies the patch
./package.sh    # fetches SDL and the demo, writes output/com.pulp.quake3_<version>_all.ipk and the manifest
```

`get-demo.sh` downloads id Software's Linux demo installer from the GWDG mirror of `ftp.idsoftware.com`. It checks the installer's sha256, then extracts `demoq3/pak0.pk3` and `Q3A_EULA.txt` into `demo/`. Neither the demo nor any other game data is kept in this repository.

To install a build by hand as root on the TV:

```sh
luna-send -i -f luna://com.webos.appInstallService/dev/install \
  '{"id":"com.pulp.quake3","ipkUrl":"/tmp/com.pulp.quake3_1.2.0_all.ipk","subscribe":true}'
```

## License

The engine, the patch and the scripts are GPLv2, like ioquake3; see `LICENSE`. SDL is under the zlib license. The Quake III Arena demo data belongs to id Software and is distributed under its own license, `Q3A_EULA.txt`. Quake III Arena is a trademark of id Software; this is an unofficial port, not affiliated with id Software.
