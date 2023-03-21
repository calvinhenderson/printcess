#!/usr/bin/env sh

usage() {
	echo "usage: $0 source_icon"
	echo "\tsource_icon: The path to the source image (1024x1024)"
}

if [ "$#" -ne 1 ]; then
	usage
	exit 1;
fi

SRC_ICON="$1"
ICONSET="./$SRC_ICON.iconset"

mkdir $1.iconset
sips -z 16 16     "$SRC_ICON" --out "$ICONSET"/icon_16x16.png
sips -z 32 32     "$SRC_ICON" --out "$ICONSET"/icon_16x16@2x.png
sips -z 32 32     "$SRC_ICON" --out "$ICONSET"/icon_32x32.png
sips -z 64 64     "$SRC_ICON" --out "$ICONSET"/icon_32x32@2x.png
sips -z 128 128   "$SRC_ICON" --out "$ICONSET"/icon_128x128.png
sips -z 256 256   "$SRC_ICON" --out "$ICONSET"/icon_128x128@2x.png
sips -z 256 256   "$SRC_ICON" --out "$ICONSET"/icon_256x256.png
sips -z 512 512   "$SRC_ICON" --out "$ICONSET"/icon_256x256@2x.png
sips -z 512 512   "$SRC_ICON" --out "$ICONSET"/icon_512x512.png
cp "$SRC_ICON" "$ICONSET"/icon_512x512@2x.png
iconutil -c icns "$ICONSET"
rm -R "$ICONSET"
