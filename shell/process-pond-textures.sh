#!/bin/bash
# process-pond-textures.py — portiert nach shell
# Quelle: python, Onboarding@main:scripts/process-pond-textures.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Chroma-key pond textures to add a clean alpha channel.
#
# The leaf/blossom source webps ship on solid backgrounds (dark green or white)
# rather than transparency, so `alphaTest` clipping in three.js has nothing to
# key on. This produces RGBA PNGs with a soft alpha mask so the R3F planes clip
# to the real silhouette.

BASE="public/media/pond"
OUT="$BASE/processed"

mkdir -p "$OUT"

# Function to key out background and create alpha channel
key_out() {
    local path="$1"
    local out="$2"
    local mode="$3"
    local feather="${4:-2}"

    # Use ImageMagick to process the image
    if [[ "$mode" == "green" ]]; then
        # Dark-green background: low overall brightness AND green-dominant-but-dark.
        # Foreground leaf is much brighter / lighter green.
        convert "$path" \
            \( +clone -colorspace Gray -threshold 40 \) \
            \( +clone -channel G -separate \
               \( -clone 0 -channel RGB -separate -delete 1,2 \) \
               -delete 0 -fx 'u[0] < v[0]' \) \
            -compose multiply -composite \
            -blur 0x"$feather" \
            "$out"
    elif [[ "$mode" == "white" ]]; then
        # White background: near-white, low saturation.
        convert "$path" \
            \( +clone -colorspace HSL -channel L -separate +channel \
               -threshold 218 \
               \( +clone -evaluate set 0 \) \
               +swap -threshold 28 -morphology close disk:1 \) \
            -alpha off \
            -blur 0x"$feather" \
            "$out"
    else
        echo "Invalid mode: $mode" >&2
        exit 1
    fi

    # Trim the image to content bounds
    mogrify -trim +repage "$out"

    echo "$(basename "$path") -> $(basename "$out") ($(identify -format "%wx%h" "$out")) ($mode)"
}

# Process images
key_out "$BASE/blaetter/12130585.webp" "$OUT/leaf-a.png" "green"
key_out "$BASE/blaetter/48178242.webp" "$OUT/leaf-b.png" "white"
key_out "$BASE/blueten/78370994.webp" "$OUT/blossom-a.png" "white" 3
key_out "$BASE/blueten/70017289.webp" "$OUT/blossom-b.png" "white" 3

echo "done"
