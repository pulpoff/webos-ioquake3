#!/bin/sh
# Fetches the Quake III Arena demo data: id Software's Linux demo installer (1.11-6) from the
# GWDG mirror of ftp.idsoftware.com, checked by sha256, unpacked to demo/demoq3/pak0.pk3 and
# demo/Q3A_EULA.txt. The EULA allows free, non-commercial copies that carry the EULA with them.
set -e
cd "$(dirname "$0")"
URL=https://ftp.gwdg.de/pub/misc/ftp.idsoftware.com/idstuff/quake3/linux/linuxq3ademo-1.11-6.x86.gz.sh
SHA256=64dee3f69b6e792d1da4fe0ac98fedc7eb1e37ea1027fb609a9fadd06150a4ec
I=downloads/linuxq3ademo-1.11-6.x86.gz.sh
mkdir -p downloads demo
[ -f "$I" ] || curl -fL -o "$I" "$URL"
echo "$SHA256  $I" | sha256sum -c -
# a shell header of 164 lines, then a gzipped tar
tail -n +165 "$I" | gzip -cd | tar -x -C demo demoq3/pak0.pk3 Help/Q3A_EULA.txt
mv -f demo/Help/Q3A_EULA.txt demo/Q3A_EULA.txt && rmdir demo/Help
ls -l demo/demoq3/pak0.pk3 demo/Q3A_EULA.txt
