#!/bin/sh
# Packages the build (./build.sh) into output/<id>_<version>_all.ipk, in the layout
# ares-package produces, plus output/<id>.manifest.json for the Homebrew Channel. It adds:
# - webosbrew's SDL 2.30.12 webOS port (release 2.30.12-webos.1, the build RetroArch ships),
#   downloaded once and checked by sha256; the TV's own SDL is 2.0.10;
# - the Quake III Arena demo with its EULA (./get-demo.sh fetches it), so the game plays
#   out of the box, with a copy of the native game modules next to it in demoq3/.
set -e
cd "$(dirname "$0")"
TC=toolchain/arm-webos-linux-gnueabi_sdk-buildroot/bin/arm-webos-linux-gnueabi
SDL_URL=https://github.com/webosbrew/SDL-webOS/releases/download/release-2.30.12-webos.1/SDL2-2.30.12-webos-abi.tar.gz
SDL_SHA256=b43c05b26c0a0431a2b26a9b7036a24d8a34989441aeb87dd2825c1b50cbe83b
DEMO_MD5=0613b3d4ef05e613a2b470571498690f
ID=$(sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' app/appinfo.json)
VER=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' app/appinfo.json)

mkdir -p downloads
S=downloads/$(basename "$SDL_URL")
[ -f "$S" ] || curl -fL -o "$S" "$SDL_URL"
echo "$SDL_SHA256  $S" | sha256sum -c -
[ -f demo/demoq3/pak0.pk3 ] || ./get-demo.sh
echo "$DEMO_MD5  demo/demoq3/pak0.pk3" | md5sum -c -

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
D=$T/data/usr/palm/applications/$ID
mkdir -p "$D/lib" "$D/baseq3" "$D/missionpack" "$D/demoq3" "$T/data/usr/palm/packages/$ID" "$T/control"
cp app/appinfo.json app/gamepad.cfg app/icon.png app/largeIcon.png app/COPYING.txt "$D/"
tar -xzf "$S" -O ./lib/libSDL2-2.0.so.0.3000.12 > "$D/lib/libSDL2-2.0.so.0"
$TC-strip -o "$D/ioquake3" build/Release/ioquake3
for r in opengl1 opengl2; do $TC-strip -o "$D/renderer_$r.so" "build/Release/renderer_$r.so"; done
for g in baseq3 missionpack; do for m in cgame qagame ui; do
	$TC-strip -o "$D/$g/$m.so" "build/Release/$g/$m.so"
done; done
cp "$D"/baseq3/*.so demo/demoq3/pak0.pk3 demo/Q3A_EULA.txt "$D/demoq3/"
chmod 755 "$D/ioquake3" "$D/lib/libSDL2-2.0.so.0"; chmod 644 "$D/demoq3/pak0.pk3"
printf '{\n  "id": "%s",\n  "version": "%s",\n  "app": "%s"\n}\n' "$ID" "$VER" "$ID" > "$T/data/usr/palm/packages/$ID/packageinfo.json"
SIZE=$(du -sb "$T/data" | cut -f1)
cat > "$T/control/control" <<EOF
Package: $ID
Version: $VER
Section: misc
Priority: optional
Architecture: all
Installed-Size: $SIZE
Maintainer: N/A <nobody@example.com>
Description: This is a webOS application.
webOS-Package-Format-Version: 2
webOS-Packager-Version: x.y.x
EOF
printf '2.0\n' > "$T/debian-binary"
(cd "$T/control" && tar --owner=0 --group=0 -czf ../control.tar.gz control)
(cd "$T/data" && tar --owner=0 --group=0 -czf ../data.tar.gz usr)
mkdir -p output
OUT=output/${ID}_${VER}_all.ipk
rm -f "$OUT"
# webOS rejects GNU ar output (error -5), so write the ar container as ares-package does.
python3 - "$OUT" "$T/debian-binary" "$T/control.tar.gz" "$T/data.tar.gz" <<'PY'
import os, sys, time
out = open(sys.argv[1], 'wb'); out.write(b'!<arch>\n')
for p in sys.argv[2:]:
    data = open(p, 'rb').read()
    hdr = '%-16s%-12d%-6d%-6d%-8s%-10d`\n' % (os.path.basename(p), int(time.time()), 0, 0, '100644', len(data))
    out.write(hdr.encode()); out.write(data)
    if len(data) % 2: out.write(b'\n')
out.close()
PY
# The Homebrew Channel manifest; the release publishes it next to the IPK.
python3 - "$OUT" app/appinfo.json "output/$ID.manifest.json" <<'PY'
import hashlib, json, os, sys
ipk, info, out = sys.argv[1:]
a = json.load(open(info))
m = {
    "id": a["id"], "version": a["version"], "type": a["type"], "title": a["title"],
    "appDescription": "The Quake III Arena engine, with the demo; bring your own game data for the full game",
    "iconUri": "https://raw.githubusercontent.com/pulpoff/webos-ioquake3/main/app/largeIcon.png",
    "sourceUrl": "https://github.com/pulpoff/webos-ioquake3",
    "rootRequired": False,
    "ipkUrl": os.path.basename(ipk),
    "ipkHash": {"sha256": hashlib.sha256(open(ipk, "rb").read()).hexdigest()},
}
json.dump(m, open(out, "w"), indent=2); open(out, "a").write("\n")
PY
ls -la "$OUT" "output/$ID.manifest.json"
