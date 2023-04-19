#!/bin/bash

MIX_ENV=${MIX_ENV:-"prod"}

APP_NAME="ExPrint"
RELEASE_DIR="../_build/$MIX_ENV/rel/bakeware"
OUTPUT_DIR="_build/releases/$MIX_ENV"
# WX_LIB_PATH=`elixir -e "IO.puts :code.lib_dir(:wx, :ebin) |> Path.join('..', '..', 'priv', 'lib')"`

# Clean up previous builds
rm -rf "$OUTPUT_DIR/$APP_NAME.app"

# Create the .app file
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
cp -R "$RELEASE_DIR/." "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources"
# cp -R "$WX_LIB_PATH" "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/wx"

# Create Info.plist file
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/Info.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>CFBundleExecutable</key>
   <string>app</string>
   <key>CFBundleDisplayName</key>
   <string>$APP_NAME</string>
   <key>CFBundleIdentifier</key>
   <string>org.etownschools.$APP_NAME</string>
   <key>CFBundleName</key>
   <string>$APP_NAME</string>
   <key>CFBundleIconFile</key>
   <string>icon.icns</string>
   <key>NSHighResolutionCapable</key>
   <string>True</string>
   <key>LSMinimumSystemVersion</key>
   <string>10.12</string>
   <key>LSArchitecturePriority</key>
   <array>
     <string>x86_64</string>
   </array>
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
   </dict>
</dict>
</plist>
EOL

# Convert the icon.png to icon.icns
ICON_FILE="../priv/icon.png" # Update this with the path to your icon.png file
ICONSET_DIR="$OUTPUT_DIR/icon.iconset"

mkdir -p "$ICONSET_DIR"
cp "$ICON_FILE" "$ICONSET_DIR/icon_1024x1024.png"

sips -z 16 16 "$ICON_FILE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32 "$ICON_FILE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32 "$ICON_FILE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64 "$ICON_FILE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128 "$ICON_FILE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256 "$ICON_FILE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256 "$ICON_FILE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512 "$ICON_FILE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512 "$ICON_FILE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$ICON_FILE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/icon.icns"
rm -rf "$ICONSET_DIR"

# Make the .app file executable
chmod +x "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/app"

# # Create the app.entitlements file
# cat > "$(pwd)/$APP_NAME.entitlements" <<EOL
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
#   <key>com.apple.security.cs.allow-jit</key>
#   <true/>
#   <key>com.apple.security.cs.disable-library-validation</key>
#   <true/>
#   <key>com.apple.security.cs.allow-dyld-environment-variables</key>
#   <true/>
# </dict>
# </plist>
# EOL
# 
# # Sign the app with entitlements
# codesign --force --sign - --entitlements "$(pwd)/$APP_NAME.entitlements" "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
# rm "$(pwd)/$APP_NAME.entitlements"

echo "macOS app bundle created successfully at $OUTPUT_DIR/$APP_NAME.app"

# Print the file size of the .app file
echo " * size: $(du -sh "$OUTPUT_DIR/$APP_NAME.app")"
