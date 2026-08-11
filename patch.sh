#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f "eboot.bin" ]; then
    echo "Put your eboot.bin in this folder."
    sleep 2
    exit 0
fi

# Calcula el hash MD5 (en mayúsculas, como PowerShell)
FILE_HASH=$(md5sum eboot.bin | awk '{print $1}' | tr '[:lower:]' '[:upper:]')

mkdir -p output

patched=0

# Función auxiliar: escribe un byte (en hex, ej. "01") en un offset (decimal) de un archivo
patch_byte() {
    local file="$1"
    local offset="$2"
    local hexbyte="$3"
    printf "\\x${hexbyte}" | dd of="$file" bs=1 seek="$offset" count=1 conv=notrunc status=none
}

#Diva F US
# values to change 02 - 01
#0x4f767e 02 20           movs       param_1,#0x2
# values to change 02 - 01 
#0x14764 02 20           movs       r0,#0x2
# values to change F6 - F7 
#0x149e8 f6 ee 00 0a     vmov.f32   s1,0x3f000000


# Diva X US

# 0x31d06 02 22           movs       r2,#0x2




# Diva X 60fps patch by someone idk who
if [ "$FILE_HASH" = "733033E2DDF86D94FCA30B2AA1249302" ]; then
    echo "Patching 60fps Diva X ASIA"
    cp eboot.bin output/eboot.bin
    patch_byte output/eboot.bin $((0x3A32C)) 01
    patch_byte output/eboot.bin $((0x3AA5A)) f7
    patched=1
fi

# Diva X 60fps patch reference the patch above
if [ "$FILE_HASH" = "04A530196C722D1A475082C57D85CFD7" ]; then
    echo "Patching 60fps Diva X JP"
    cp eboot.bin output/eboot.bin
    patch_byte output/eboot.bin $((0x3A320)) 01
    patch_byte output/eboot.bin $((0x3AA4E)) f7
    patched=1
fi

if [ "$FILE_HASH" = "9E50BD28879FC721AB724E97141F9D8A" ]; then
    echo "Patching 60fps Miracle Girls Festival"
    cp eboot.bin output/eboot.bin
    patch_byte output/eboot.bin $((0x4F464)) 01
    patch_byte output/eboot.bin $((0x4F5C0)) f7
    patched=1
fi

#if [ "$FILE_HASH" = "3727CEE0C28313B961634C15B3F7EA33" ]; then
    echo "Patching 60fps Diva f US"
    cp eboot.bin output/eboot.bin
    patch_byte output/eboot.bin $((0x4F767E)) 01
    patch_byte output/eboot.bin $((0x14764)) 01
    patch_byte output/eboot.bin $((0x149E8)) f7
    patched=1
#fi

if [ "$FILE_HASH" = "94AA36566BACEA2DC53ACA96920B3EC3" ]; then
    echo "Patching 60fps Diva f JP"
    cp eboot.bin output/eboot.bin
    patch_byte output/eboot.bin $((0x4A5316)) 01
    patch_byte output/eboot.bin $((0x142A6)) 01
    patch_byte output/eboot.bin $((0x14538)) f7
    patched=1
fi

if [ "$FILE_HASH" = "F161E1D7BB0CA56BBBB56A7B8794F52D" ]; then
    echo "Patching 60fps Diva F 2nd JP"
    cp eboot.bin output/eboot.bin
    patch_byte output/eboot.bin $((0xBA3C)) 01
    patch_byte output/eboot.bin $((0xBB9A)) f7
    patched=1
fi

if [ "$patched" -eq 1 ]; then
    echo "Done. output/eboot.bin"
else
    echo "Game is not supported."
fi

sleep 2