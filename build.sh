#!/bin/sh
# Builds ioquake3 for webOS TVs into build/. On the first run it downloads the openlgtv
# webOS toolchain into toolchain/ and clones upstream ioquake3 into ioq3/ at the pinned
# commit, with patches/ioq3-webos.patch applied. Run ./package.sh afterwards.
set -e
cd "$(dirname "$0")"
IOQ3_COMMIT=52088b9eae247d8e321c8dc1fb49a879652854f9
TC_URL=https://github.com/openlgtv/buildroot-nc4/releases/download/2026.08-webos/arm-webos-linux-gnueabi_sdk-buildroot-x86_64.tar.gz
T=$PWD/toolchain/arm-webos-linux-gnueabi_sdk-buildroot

if [ ! -x "$T/bin/cmake" ]; then
	mkdir -p toolchain
	curl -fL "$TC_URL" | tar -xz -C toolchain
	"$T/relocate-sdk.sh"
fi
if [ ! -d ioq3/.git ]; then
	git clone https://github.com/ioquake/ioq3.git ioq3
	git -C ioq3 checkout -q "$IOQ3_COMMIT"
	git -C ioq3 apply ../patches/ioq3-webos.patch
fi

# Cortex-A55 code in 32-bit mode with the softfp calling convention of webOS's userland:
# TVs with an ARMv8 (64-bit capable) CPU.
"$T/bin/cmake" -S ioq3 -B build -DCMAKE_TOOLCHAIN_FILE="$T/share/buildroot/toolchainfile.cmake" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS="-mcpu=cortex-a55 -mfpu=neon-fp-armv8 -mfloat-abi=softfp -D_FILE_OFFSET_BITS=64 -DWEBOS" \
	-DCMAKE_BUILD_RPATH='$ORIGIN/lib' -DBUILD_SERVER=OFF \
	-DBUILD_RENDERER_GL1=ON -DBUILD_RENDERER_GL2=ON -DUSE_RENDERER_DLOPEN=ON \
	-DUSE_OPENAL=OFF -DUSE_HTTP=OFF -DUSE_VOIP=OFF -DUSE_MUMBLE=OFF \
	-DBUILD_GAME_QVMS=OFF -DBUILD_GAME_LIBRARIES=ON -DUSE_INTERNAL_SDL=OFF
"$T/bin/cmake" --build build -j"$(nproc)"
