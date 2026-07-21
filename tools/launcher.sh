#!/bin/bash
# Build a game's launcher art from one of its screenshots.
#
#   tools/launcher.sh <game> [source.png] [Title]
#
# Writes games/<game>/launcher/{card,card-pressed,icon,launchImage}.png
# in the shapes the system launcher and play.date sideload expect:
#
#   card.png         350x155  the shelf card: scene + black title bar
#   card-pressed.png 350x155  same, scene inverted (the press state)
#   icon.png          32x32   white tile, black border, the initial
#   launchImage.png  400x240  the full screen shown while loading
#
# Everything is forced to 1-bit: text is drawn with antialiasing off
# and the result is thresholded, because a launcher PNG with grey
# pixels in it is a launcher PNG the device will dither for you.
#
# Defaults to build/<game>-mid.png, which tools/smoke.sh leaves behind.

set -eu
GAME="${1:?usage: launcher.sh <game> [source.png] [Title]}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${2:-$ROOT/build/$GAME-mid.png}"
TITLE="${3:-$(echo "$GAME" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')}"
OUT="$ROOT/games/$GAME/launcher"
INITIAL="$(echo "$TITLE" | cut -c1)"

[ -f "$SRC" ] || { echo "no source screenshot: $SRC"; exit 1; }
mkdir -p "$OUT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The source is a live screenshot, so crop the HUD bands off the top
# and bottom first — a shelf card wants the game's world on it, not
# its status text at 87% scale.
CROP="${CROP:-400x196+0+22}"

# 348x135 scene + 348x18 title bar, then a 1px white frame = 350x155
magick "$SRC" -crop "$CROP" +repage -resize 348x135! "$TMP/scene.png"
magick -size 348x18 xc:black +antialias -fill white \
    -pointsize 15 -gravity center -annotate +0+0 "$TITLE" "$TMP/bar.png"

magick "$TMP/scene.png" "$TMP/bar.png" -append \
    -bordercolor white -border 1 -threshold 50% -depth 1 \
    "$OUT/card.png"

magick "$TMP/scene.png" -negate "$TMP/pressed.png"
magick "$TMP/pressed.png" "$TMP/bar.png" -append \
    -bordercolor white -border 1 -threshold 50% -depth 1 \
    "$OUT/card-pressed.png"

magick -size 32x32 xc:white +antialias \
    -stroke black -strokewidth 1 -fill none -draw "rectangle 0,0 31,31" \
    -stroke none -fill black -pointsize 22 -gravity center \
    -annotate +0+1 "$INITIAL" \
    -threshold 50% -depth 1 "$OUT/icon.png"

magick "$SRC" -resize 400x240! -threshold 50% -depth 1 "$OUT/launchImage.png"

for f in card card-pressed icon launchImage; do
    printf '%s: ' "$f"
    magick identify -format '%wx%h %[colorspace] %z-bit\n' "$OUT/$f.png"
done
