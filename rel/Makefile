# Makefile to build and package an Elixir application for macOS.
#
# This Makefile leverages `mix release` to create a self-contained Elixir
# application and then wraps it into a standard macOS .app bundle.
# It also includes steps to bundle ImageMagick if your Elixir application
# interacts with it via System.cmd/3.
#
# Prerequisites:
# - Homebrew (https://brew.sh/)
# - Elixir (brew install elixir)
# - ImageMagick (brew install imagemagick)

# --- Configuration Variables ---
# The name of your Elixir application (as defined in mix.exs)
APP_NAME := print_client
# The version of your macOS application (can be different from Elixir app version)
APP_VERSION := 1.0.0
# The path to your Elixir application's root directory
APP_SOURCE_DIR := ..

# Build directories
BUILD_DIR := _build
RELEASE_DIR := $(BUILD_DIR)/prod/rel/$(APP_NAME)
MACOS_APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
MACOS_APP_CONTENTS := $(MACOS_APP_DIR)/Contents
MACOS_APP_BIN_DIR := $(MACOS_APP_CONTENTS)/MacOS
MACOS_APP_RESOURCES_DIR := $(MACOS_APP_CONTENTS)/Resources

# Homebrew paths for dependencies to bundle
# Adjust these if your Homebrew installation path is different
HOMEBREW_PREFIX := $(shell brew --prefix)
IMAGEMAGICK_BIN_DIR := $(HOMEBREW_PREFIX)/bin
IMAGEMAGICK_LIB_DIR := $(HOMEBREW_PREFIX)/lib

# --- Targets ---

.PHONY: all clean build_elixir_app package_macos_app bundle_imagemagick info

all: build_elixir_app package_macos_app
	@echo "----------------------------------------------------"
	@echo "Elixir macOS application build complete!"
	@echo "Your application is located at: $(MACOS_APP_DIR)"
	@echo "You can run it by double-clicking or via 'open $(MACOS_APP_DIR)'"
	@echo "----------------------------------------------------"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete."

info:
	@echo "--- Build Information ---"
	@echo "App Name: $(APP_NAME)"
	@echo "App Version: $(APP_VERSION)"
	@echo "Elixir Source Dir: $(APP_SOURCE_DIR)"
	@echo "Build Directory: $(BUILD_DIR)"
	@echo "Release Directory: $(RELEASE_DIR)"
	@echo "macOS App Directory: $(MACOS_APP_DIR)"
	@echo "Homebrew Prefix: $(HOMEBREW_PREFIX)"
	@echo "-------------------------"

# --- Elixir Application Build ---

# Target to ensure all Elixir dependencies are fetched
$(APP_SOURCE_DIR)/mix.lock: $(APP_SOURCE_DIR)/mix.exs
	@echo "Fetching Elixir dependencies..."
	cd $(APP_SOURCE_DIR) && mix deps.get --only prod
	touch $(APP_SOURCE_DIR)/mix.lock # Create a dummy mix.lock if it doesn't exist to mark deps as fetched

# Target to build the Elixir release
build_elixir_app: $(APP_SOURCE_DIR)/mix.lock
	@echo "Building Elixir application release (MIX_ENV=prod)..."
	cd $(APP_SOURCE_DIR) && MIX_ENV=prod mix release --overwrite
	@echo "Elixir application release built to: $(RELEASE_DIR)"

# --- macOS Application Packaging ---

# Target to create the basic .app bundle structure
$(MACOS_APP_CONTENTS)/Info.plist:
	@echo "Creating macOS .app bundle structure and Info.plist..."
	mkdir -p $(MACOS_APP_BIN_DIR)
	mkdir -p $(MACOS_APP_RESOURCES_DIR)
	# Create Info.plist for the macOS application bundle
	# This file provides metadata about your application
	cat > $@ <<EOL \
<?xml version="1.0" encoding="UTF-8"?> \
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> \
<plist version="1.0"> \
<dict> \
	<key>CFBundleExecutable</key> \
	<string>$(APP_NAME)</string> \
	<key>CFBundleIdentifier</key> \
	<string>com.yourcompany.$(APP_NAME)</string> \
	<key>CFBundleName</key> \
	<string>$(APP_NAME)</string> \
	<key>CFBundleDisplayName</key> \
	<string>$(APP_NAME)</string> \
	<key>CFBundlePackageType</key> \
	<string>APPL</string> \
	<key>CFBundleShortVersionString</key> \
	<string>$(APP_VERSION)</string> \
	<key>CFBundleVersion</key> \
	<string>$(APP_VERSION)</string> \
	<key>LSMinimumSystemVersion</key> \
	<string>10.15</string> \
	<key>NSHighResolutionCapable</key> \
	<true/> \
</dict> \
</plist> \
EOL

# Target to copy the Elixir release into the .app bundle
$(MACOS_APP_RESOURCES_DIR)/$(APP_NAME)_release: $(MACOS_APP_CONTENTS)/Info.plist
	@echo "Copying Elixir release into .app bundle resources..."
	cp -R $(RELEASE_DIR) $(MACOS_APP_RESOURCES_DIR)/$(APP_NAME)_release
	@echo "Elixir release copied."

# Target to bundle ImageMagick binaries and libraries
# This is crucial if your Elixir app uses `System.cmd("convert", ...)`
bundle_imagemagick: $(MACOS_APP_RESOURCES_DIR)/$(APP_NAME)_release
	@echo "Bundling ImageMagick binaries and libraries..."
	mkdir -p $(MACOS_APP_RESOURCES_DIR)/imagemagick/bin
	mkdir -p $(MACOS_APP_RESOURCES_DIR)/imagemagick/lib
	# Copy ImageMagick binaries (e.g., 'convert')
	cp -L $(IMAGEMAGICK_BIN_DIR)/convert $(MACOS_APP_RESOURCES_DIR)/imagemagick/bin/
	# Copy essential ImageMagick dynamic libraries
	# This might need adjustment based on specific ImageMagick dependencies.
	# Use `otool -L $(IMAGEMAGICK_BIN_DIR)/convert` to see its direct dependencies.
	# We're copying common ones here.
	cp -L $(IMAGEMAGICK_LIB_DIR)/libImageMagick*.dylib $(MACOS_APP_RESOURCES_DIR)/imagemagick/lib/ 2>/dev/null || true
	cp -L $(IMAGEMAGICK_LIB_DIR)/libMagick*.dylib $(MACOS_APP_RESOURCES_DIR)/imagemagick/lib/ 2>/dev/null || true
	# Ensure the copied libraries are made relative to the bundle
	# This is a complex step often handled by specialized tools like `macdeployqt` or `install_name_tool`
	# For simplicity, we'll rely on DYLD_LIBRARY_PATH in the launch script.
	@echo "ImageMagick bundled."

# Target to create the main executable script for the .app bundle
$(MACOS_APP_BIN_DIR)/$(APP_NAME): $(MACOS_APP_RESOURCES_DIR)/$(APP_NAME)_release bundle_imagemagick
	@echo "Creating macOS application executable script..."
	cat > $@ <<EOL \
#!/bin/bash \
# This script launches the Elixir application bundled within the .app \
 \
# Get the directory of the current script (i.e., Contents/MacOS) \
SCRIPT_DIR="\$(dirname "\$(realpath "\$0")")" \
# Navigate to the Resources directory where the Elixir release is located \
APP_RESOURCES_DIR="\$(dirname "\$SCRIPT_DIR")/Resources" \
ELIXIR_RELEASE_PATH="\${APP_RESOURCES_DIR}/$(APP_NAME)_release" \
 \
# Add bundled ImageMagick binaries to PATH \
export PATH="\${APP_RESOURCES_DIR}/imagemagick/bin:\$PATH" \
# Add bundled ImageMagick libraries to DYLD_LIBRARY_PATH \
# This is crucial for macOS to find dynamically linked libraries \
export DYLD_LIBRARY_PATH="\${APP_RESOURCES_DIR}/imagemagick/lib:\$DYLD_LIBRARY_PATH" \
 \
# Execute the Elixir release start script \
# The `_build/prod/rel/my_elixir_app/bin/my_elixir_app` is the actual executable \
exec "\${ELIXIR_RELEASE_PATH}/bin/$(APP_NAME)" start "\$@" \
EOL
	chmod +x $@
	@echo "Executable script created."

# Main packaging target
package_macos_app: $(MACOS_APP_BIN_DIR)/$(APP_NAME)
	@echo "macOS application packaging complete."

# --- Helper for Mix Release (if needed, though mix release handles it) ---
# This target is more for reference, as `mix release` handles compilation.
# compile_elixir_app:
# 	@echo "Compiling Elixir application..."
# 	cd $(APP_SOURCE_DIR) && MIX_ENV=prod mix compile
# 	@echo "Elixir application compiled."

