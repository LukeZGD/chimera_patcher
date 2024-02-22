#!/bin/bash
# This is basically just a copy of https://gist.github.com/jakeajames/b44d8db345769a7149e97f5e155b3d46
# and https://github.com/LukeZGD/ohd

cd "$(dirname "$0")"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/input_ipa"
    exit 1
fi

if ! [ -f "$1" ]; then
    echo "$1 does not exist"
    exit 1
fi

origSHA1="6fe6517f6ba4b2e826b8a53bcc15c08e231ac672"

if [ $(uname) == "Darwin" ]; then
    bspatch="$(which bspatch)"
    hash_local="$(shasum -a 1 "$1" | awk '{print $1}')"
else
    if [[ $(uname -m) == "a"* && $(getconf LONG_BIT) == 64 ]]; then
        platform_arch="arm64"
    elif [[ $(uname -m) == "a"* ]]; then
        platform_arch="armhf"
    elif [[ $(uname -m) == "x86_64" ]]; then
        platform_arch="x86_64"
    fi
    bspatch="bin/linux/$platform_arch/bspatch"
    hash_local="$(sha1sum "$1" | awk '{print $1}')"
fi

if [ "$hash_local" != "$origSHA1" ]; then
    echo "$1 SHA1sum mismatch. Expected $origSHA1, got $hash_local"
    echo "Your copy of the .ipa may be corrupted or incomplete."
    exit 1
fi

output="Chimera-patched.ipa"

if [ -f "$output" ]; then
    echo "$output already exists"
    exit 1
fi

echo "Setting up environment"

tmpDir="/tmp/unpacked"

mkdir -p "$tmpDir"

# -p will ignore if dir already exists
# can just purge everything in the dir

rm -rfv "$tmpDir"/*

echo "Extracting"

unzip -q "$1" -d "$tmpDir"

if [ $? != 0 ]; then
    echo "can't unzip $1"
    rm -rf "$tmpDir"
    exit 1
fi

echo "Patching"
mv "$tmpDir/Payload/Chimera.app/Chimera" .
$bspatch Chimera "$tmpDir/Payload/Chimera.app/Chimera" Chimera.patch
rm Chimera

echo "Compressing"

CD=$(pwd)

cd "$tmpDir"

if [[ "$output" = /* ]]; then
    zip -r "$output" Payload/ > /dev/null
else
    zip -r "$CD/$output" Payload/ > /dev/null
fi

if [ $? != 0 ]; then
    echo "can't zip $1"
    rm -rf "$tmpDir"
    cd - > /dev/null
    exit 1
fi

cd - > /dev/null

rm -rf "$tmpDir"

echo "Done. Output is $output"
