# Makefile for building a portable Elixir/Erlang environment on Apple Silicon
#
# Usage:
#   make                - Build all components and package the .app bundle
#   make -j$(nproc)     - Build in parallel (e.g., make -j8)
#   make clean          - Remove all build artifacts and the .app bundle
#   make bundle         - Package the app after a successful build
#   make OTP_VERSION=26.2.2 - Build with a specific version

.PHONY: all clean clean-bundle patch-linker-paths info installer bundle sign app run

# --- General Configuration ---
ELIXIR_VERSION ?= 1.19.5
OTP_VERSION    ?= 27.3
ARCH           := aarch64
MACOSX_DEPLOYMENT_TARGET := 14
BUILD_DIR      := $(shell pwd)/_build
NCPU           := $(shell sysctl -n hw.ncpu)

# --- Elixir App Configuration ---
APP_SRC_DIR      := ..
APP_RELEASE_NAME := app

# --- Application Bundle Configuration ---
APP_NAME          := Printcess
BUNDLE_IDENTIFIER := com.calvinhenderson.print-client
APP_BUNDLE_DIR    := $(BUILD_DIR)/$(APP_NAME).app
MACOS_DIR         := $(APP_BUNDLE_DIR)/Contents/MacOS
RESOURCES_DIR     := $(APP_BUNDLE_DIR)/Contents/Resources
FRAMEWORKS_DIR    := $(APP_BUNDLE_DIR)/Contents/Frameworks
INFO_PLIST        := $(APP_BUNDLE_DIR)/Contents/Info.plist
LAUNCHER_SCRIPT   := $(MACOS_DIR)/$(APP_NAME)
ICON_SOURCE_PNG   := $(APP_SRC_DIR)/priv/icon.png
ICONSET_DIR       := $(BUILD_DIR)/$(APP_NAME).iconset
ICON_ICNS         := $(RESOURCES_DIR)/AppIcon.icns
APP_RELEASE_DIR   := $(RESOURCES_DIR)/app
APP_INSTALLER     := $(BUILD_DIR)/$(APP_NAME).dmg
SIGN_IDENTITY     ?= -

# --- Source and Release Directories ---
OPENSSL_CC := darwin64-arm64-cc
OPENSSL_VERSION := 3.5
OPENSSL_BRANCH  := openssl-$(OPENSSL_VERSION)
OPENSSL_SRC_DIR := $(BUILD_DIR)/openssl_src
OPENSSL_REL_DIR := $(BUILD_DIR)/openssl-rel-$(OPENSSL_VERSION)-$(ARCH)

WXWIDGETS_VERSION := 3.2.2
WXWIDGETS_SRC_DIR := $(BUILD_DIR)/wxwidgets_src
WXWIDGETS_REL_DIR := $(BUILD_DIR)/wxwidgets-rel-$(subst .,_,$(WXWIDGETS_VERSION))-$(ARCH)

ERLANG_TAG      := OTP-$(OTP_VERSION)
ERLANG_SRC_DIR  := $(BUILD_DIR)/erlang_otp_src
ERLANG_REL_DIR  := $(BUILD_DIR)/erlang-otp-$(subst .,_,$(OTP_VERSION))-$(ARCH)

ELIXIR_TAG      := v$(ELIXIR_VERSION)
ELIXIR_SRC_DIR  := $(BUILD_DIR)/elixir_src

MAGICK_VERSION := 7.1.2-2
MAGICK_SRC_DIR := $(BUILD_DIR)/magick_src
MAGICK_REL_DIR := $(BUILD_DIR)/magick-rel-$(subst .,_,$(MAGICK_VERSION))-$(ARCH)

# --- Stamp Files ---
OPENSSL_STAMP   := $(BUILD_DIR)/.openssl.done
WXWIDGETS_STAMP := $(BUILD_DIR)/.wxwidgets.done
ERLANG_STAMP    := $(BUILD_DIR)/.erlang.done
ELIXIR_STAMP    := $(BUILD_DIR)/.elixir.done
MAGICK_STAMP    := $(BUILD_DIR)/.magick.done

# --- Main Targets ---
all: bundle info

$(OPENSSL_STAMP) $(WXWIDGETS_STAMP) $(ERLANG_STAMP) $(ELIXIR_STAMP) $(MAGICK_STAMP): | $(BUILD_DIR)
$(BUILD_DIR):
	@mkdir -p "$@"

# --- Dependency Build Recipes ---

$(OPENSSL_STAMP):
	@echo "✅ Building OpenSSL..."
	@if [ ! -d "$(OPENSSL_SRC_DIR)" ]; then \
		git clone --branch "$(OPENSSL_BRANCH)" https://github.com/openssl/openssl.git "$(OPENSSL_SRC_DIR)"; \
	fi
	@cd "$(OPENSSL_SRC_DIR)" && \
		export CFLAGS="-mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)" && \
		./Configure "$(OPENSSL_CC)" \
			--prefix="$(OPENSSL_REL_DIR)" && \
		make -j$(NCPU) && \
		make install
	@touch $@

$(WXWIDGETS_STAMP):
	@echo "✅ Building wxWidgets..."
	@if [ ! -d "$(WXWIDGETS_SRC_DIR)" ]; then \
		git clone --branch "v$(WXWIDGETS_VERSION)" https://github.com/wxWidgets/wxWidgets.git "$(WXWIDGETS_SRC_DIR)"; \
	fi
	@cd "$(WXWIDGETS_SRC_DIR)" && git submodule update --init --recursive;
	@rm -rf "$(WXWIDGETS_REL_DIR)"
	@mkdir -p "$(WXWIDGETS_SRC_DIR)/build"
	@cd "$(WXWIDGETS_SRC_DIR)/build" && \
		../configure \
			--prefix="$(WXWIDGETS_REL_DIR)" \
			--with-macosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) \
			--with-osx_cocoa \
			--with-opengl \
			--with-libpng=builtin \
			--with-libjpeg=builtin \
			--with-libtiff=builtin \
			--with-zlib=builtin \
			--with-expat=builtin \
			--disable-debug \
			--enable-webview \
			--enable-webviewwebkit \
			--enable-monolithic \
			--enable-unicode && \
		make -j$(NCPU) && \
		make install
	@touch $@

$(ERLANG_STAMP): $(WXWIDGETS_STAMP) $(OPENSSL_STAMP)
	@echo "✅ Building Erlang/OTP $(OTP_VERSION)..."
	@if [ ! -d "$(ERLANG_SRC_DIR)" ]; then \
		git clone https://github.com/erlang/otp.git "$(ERLANG_SRC_DIR)"; \
	fi
	@cd "$(ERLANG_SRC_DIR)" && \
		git fetch --tags && \
		git checkout "$(ERLANG_TAG)" && \
		git submodule update --init --recursive
	@cd "$(ERLANG_SRC_DIR)" && \
		export PATH="$(WXWIDGETS_REL_DIR)/bin:$(OPENSSL_REL_DIR)/bin:$$PATH" && \
		export ERL_TOP="$(ERLANG_SRC_DIR)" && \
		export MACOSX_DEPLOYMENT_TARGET="$(MACOSX_DEPLOYMENT_TARGET)" && \
		./configure \
			--prefix="$(ERLANG_REL_DIR)" \
			--with-ssl="$(OPENSSL_REL_DIR)" \
			--with-wx-config="$(WXWIDGETS_REL_DIR)/bin/wx-config" \
			--without-javac \
			--without-jinterface \
			--without-odbc \
			--with-opengl \
			--enable-wx \
			--enable-shared \
			--disable-dynamic-ssl-lib \
			--disable-debug && \
		make -j$(NCPU) && \
		make install
	@touch $@

$(ELIXIR_STAMP): $(ERLANG_STAMP)
	@echo "✅ Building Elixir v$(ELIXIR_VERSION)..."
	@if [ ! -d "$(ELIXIR_SRC_DIR)" ]; then \
		git clone --branch "$(ELIXIR_TAG)" https://github.com/elixir-lang/elixir.git "$(ELIXIR_SRC_DIR)"; \
	fi
	@cd "$(ELIXIR_SRC_DIR)" && \
		export PATH="$(ERLANG_REL_DIR)/bin:$$PATH" && \
		make clean && \
		make PREFIX="$(ERLANG_REL_DIR)" install
	@touch $@

$(MAGICK_STAMP):
	@echo "✅ Building ImageMagick v$(MAGICK_VERSION)..."
	@if [ ! -d "$(MAGICK_SRC_DIR)" ]; then \
		git clone --branch "$(MAGICK_VERSION)" https://github.com/ImageMagick/ImageMagick.git "$(MAGICK_SRC_DIR)"; \
	fi
	@mkdir -p "$(MAGICK_SRC_DIR)/build"
	@cd "$(MAGICK_SRC_DIR)/build" && \
		../configure \
			--prefix="$(MAGICK_REL_DIR)" \
			--disable-shared --with-rsvg --without-modules --without-hdri \
			--without-bzlib --without-autotrace --without-djvu --without-dps --without-fftw \
			--without-flif --without-fpx --without-fontconfig --without-gslib --without-gvc \
			--without-heic --without-jbig --without-jpeg --without-jxl --without-dmr \
			--without-lcms --without-lqr --without-ltdl --without-lzma --without-magick-plus-plus \
			--without-openexr --without-openjp2 --without-pango --without-perl --without-png \
			--without-raqm --without-raw --without-tiff --without-uhdr --without-webp \
			--without-wmf --without-x --without-xml --without-zip --without-zlib --without-zstd \
			&& \
		make -j$(NCPU) && \
		make install
	@touch $@

# --- Elixir Application Release ---

app: $(ELIXIR_STAMP) $(MAGICK_STAMP)
	@echo "✅ Building Elixir application release..."
	@if [ ! -d "$(APP_SRC_DIR)" ]; then \
		echo "🛑 Error: Elixir application source directory not found at '$(APP_SRC_DIR)'"; \
		exit 1; \
	fi
	@cd "$(APP_SRC_DIR)" && \
		export PATH="$(ERLANG_REL_DIR)/bin:$$PATH" && \
		export MIX_ENV=prod && \
		export EXQLITE_SYSTEM_CFLAGS="-mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)" && \
		mix local.hex --force && \
		mix local.rebar --force && \
		mix deps.get --only prod && \
		mix assets.setup && \
		mix assets.deploy && \
		mix release

# --- App Bundle Targets ---

$(APP_BUNDLE_DIR): app $(MACOS_DIR) $(FRAMEWORKS_DIR) $(RESOURCES_DIR)
	@echo "📦 Packaging application bundle..."
	@echo " -> Copying over app release"
	@cp -R $(APP_SRC_DIR)/_build/prod/rel/$(APP_RELEASE_NAME) $(RESOURCES_DIR)/
	@echo " -> Copying over runtime dependencies"
	@cp -R $(WXWIDGETS_REL_DIR)/lib/*.dylib $(FRAMEWORKS_DIR)/
	@cp -R $(MAGICK_REL_DIR)/bin/magick $(MACOS_DIR)/magick

$(INFO_PLIST): $(APP_BUNDLE_DIR)/Contents
	@echo "  -> Generating Info.plist..."
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	@echo '<plist version="1.0"><dict>' >> $@
	@echo '    <key>CFBundleIdentifier</key><string>$(BUNDLE_IDENTIFIER)</string>' >> $@
	@echo '    <key>CFBundleName</key><string>$(APP_NAME)</string>' >> $@
	@echo '    <key>CFBundleExecutable</key><string>$(APP_NAME)</string>' >> $@
	@echo '    <key>CFBundleIconFile</key><string>AppIcon</string>' >> $@
	@echo '    <key>CFBundlePackageType</key><string>APPL</string>' >> $@
	@echo '    <key>CFBundleShortVersionString</key><string>1.0</string>' >> $@
	@echo '    <key>CFBundleVersion</key><string>1</string>' >> $@
	@echo '    <key>LSMinimumSystemVersion</key><string>$(MACOSX_DEPLOYMENT_TARGET)</string>' >> $@
	@echo '</dict></plist>' >> $@

$(LAUNCHER_SCRIPT): $(MACOS_DIR)
	@echo "  -> Generating launcher script..."
	@echo '#!/bin/bash' > $@
	@echo '# This script sets up the environment and starts the Elixir release.' >> $@
	@echo 'set -e' >> $@
	@echo 'DIR=$$(cd "$$(dirname "$$0")" && pwd)' >> $@
	@echo 'export PATH="$$DIR:$$PATH"' >> $@
	@echo 'export ERL_LIBS="$$DIR/../Resources/app/lib"' >> $@
	@echo 'export RELEASE_DIR="$$DIR/../Resources/$(APP_RELEASE_NAME)"' >> $@
	@echo '# Starts the Elixir release in the foreground' >> $@
	@echo 'export PHX_SERVER=true' >> $@
	@echo '"$$RELEASE_DIR/bin/$(APP_RELEASE_NAME)" start' >> $@
	@chmod +x $@

$(ICON_ICNS): $(ICON_SOURCE_PNG) $(RESOURCES_DIR)
	@echo "  -> Generating application icon..."
	@if [ ! -f "$(ICON_SOURCE_PNG)" ]; then \
		echo "⚠️ Warning: Icon source '$(ICON_SOURCE_PNG)' not found. Skipping icon creation."; \
		exit 0; \
	fi
	@mkdir -p "$(ICONSET_DIR)"
	@sips -z 16 16     "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_16x16.png" > /dev/null
	@sips -z 32 32     "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_16x16@2x.png" > /dev/null
	@sips -z 128 128   "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_128x128.png" > /dev/null
	@sips -z 256 256   "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_128x128@2x.png" > /dev/null
	@sips -z 256 256   "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_256x256.png" > /dev/null
	@sips -z 512 512   "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_256x256@2x.png" > /dev/null
	@sips -z 512 512   "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_512x512.png" > /dev/null
	@sips -z 1024 1024 "$(ICON_SOURCE_PNG)" --out "$(ICONSET_DIR)/icon_512x512@2x.png" > /dev/null
	@iconutil -c icns "$(ICONSET_DIR)" -o $@

$(APP_INSTALLER): $(APP_BUNDLE_DIR)
	@echo "📦 Creating installer image..."
	@rm -rf "$@.src"
	@mkdir -p "$@.src"
	@echo " -> Copying over files"
	@cp -R "$(APP_BUNDLE_DIR)" "$@.src"
	@ln -s /Applications "$@.src/Applications"
	@echo " -> Finalizing image"
	@hdiutil create -ov -volname "$(APP_NAME)" -srcfolder "$@.src" -format UDZO "$@"
	@echo " -> Signing image"
	@codesign --force --sign $(SIGN_IDENTITY) "$@"
	@echo "✅ Successfully created and signed $@"

patch-linker-paths: $(APP_BUNDLE_DIR)
	@echo "🔧 Patching linker paths..."
	@APP_BUNDLE_DIR="$(APP_BUNDLE_DIR)" APP_REL_DIR="$(APP_RELEASE_DIR)" "$(APP_SRC_DIR)/rel/patch-linker-paths.sh"

$(APP_BUNDLE_DIR)/Contents $(MACOS_DIR) $(FRAMEWORKS_DIR) $(RESOURCES_DIR):
	@mkdir -p "$@"

# --- Utility Targets ---
info:
	@echo "\n--------------------------------------------------"
	@echo "📦 Toolchains can be added to your shell path:"
	@echo "export PATH=\"$(ERLANG_REL_DIR)/bin:$(MAGICK_REL_DIR)/bin:\$$PATH\""
	@echo "🚀 Build Complete!"
	@echo "Packaged application is at: $(APP_BUNDLE_DIR)"
	@echo "--------------------------------------------------"

bundle: clean-bundle $(APP_BUNDLE_DIR) $(INFO_PLIST) $(LAUNCHER_SCRIPT) $(ICON_ICNS) patch-linker-paths sign installer

installer: bundle $(APP_INSTALLER)

sign:
	@echo "🔏 Code-signing application bundle..."
	@find "$(FRAMEWORKS_DIR)" -type f -name "*.dylib" -exec codesign --force --sign "$(SIGN_IDENTITY)" {} \;
	@find "$(APP_RELEASE_DIR)" -type f -name "*.so" -exec codesign --force --sign "$(SIGN_IDENTITY)" {} \;
	@find "$(APP_RELEASE_DIR)/bin" -type f -perm +111 -exec codesign --force --sign "$(SIGN_IDENTITY)" {} \;
	@codesign --force --sign "$(SIGN_IDENTITY)" --deep "$(APP_BUNDLE_DIR)"
	@echo "✅ Code-signing complete."

clean:
	@echo "🔥 Cleaning build directory..."
	@rm -rf "$(BUILD_DIR)/"
	@echo "🔥 Cleaning Elixir application artifacts..."
	@rm -rf "$(APP_SRC_DIR)/_build" "$(APP_SRC_DIR)/deps"

clean-bundle:
	@echo "🔥 Cleaning old bundle..."
	@rm -rf "$(APP_BUNDLE_DIR)/"
	@rm -rf "$(APP_INSTALLER)/"

run: $(LAUNCHER_SCRIPT)
	@echo "⚙️ Running bundled application.."
	@exec "$(LAUNCHER_SCRIPT)"

