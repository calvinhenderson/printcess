#!/usr/bin/env sh
set -eu

if [ -z "$APP_BUNDLE_DIR" ] || [ ! -d "$APP_BUNDLE_DIR" ]; then
	echo "Usage: APP_BUNDLE_DIR=... $0"
	echo "APP_BUNDLE_DIR is not set or the path is not a directory."
	exit 1
fi

MACOS_DIR="$APP_BUNDLE_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE_DIR/Contents/Resources"
FRAMEWORKS_DIR="$APP_BUNDLE_DIR/Contents/Frameworks"
REL_APP_DIR="$RESOURCES_DIR/app"

mkdir -p "$FRAMEWORKS_DIR"

# Build list of Mach-O files (executables, dylibs, .so)
MACHO_FILES=$(mktemp)
find "$APP_BUNDLE_DIR" -type f | while read -r f; do
	# use file utility to detect Mach-O; POSIX-safe
	if file "$f" | grep -q "Mach-O"; then
		printf '%s\n' "$f" >>"$MACHO_FILES"
	fi
done

echo "[STAGE 1]: Locating dependencies for MACHO_FILES"
while IFS= read -r bin; do
	echo " [scan] $bin"
	# parse otool output for linked libs
	otool -L "$bin" | awk 'NR>1 {print $1}' | while read -r dep; do
		case "$dep" in
		/System/Library/* | /usr/lib/* | @rpath/* | @loader_path/*)
			# ignore system and already-relative deps
			continue
			;;
		/*)
			base=$(basename "$dep")
			if [ ! -f "$FRAMEWORKS_DIR/$base" ]; then
				echo "  [copy] $dep -> $FRAMEWORKS_DIR/$base"
				cp "$dep" "$FRAMEWORKS_DIR/"
			fi
			;;
		esac
	done
done <"$MACHO_FILES"

echo "[STAGE 2]: Normalizing Frameworks dylibs (set id to @rpath and ensure loader rpath)"
# For each copied dylib, set its id and add loader rpath so it can find sibling libs
for dylib in "$FRAMEWORKS_DIR"/*.dylib; do
	[ -f "$dylib" ] || continue
	base=$(basename "$dylib")
	echo "[fix-id] $base"
	install_name_tool -id "@rpath/$base" "$dylib"
	# ensure it has @loader_path in its rpaths so it can find other frameworks in same dir
	install_name_tool -delete_rpath "@loader_path" "$dylib" 2>/dev/null || true
	install_name_tool -add_rpath "@loader_path" "$dylib" 2>/dev/null || true

	# rewrite any absolute non-system deps the dylib references to @rpath/<name>
	otool -L "$dylib" | awk 'NR>1 {print $1}' | while read -r dep; do
		case "$dep" in
		/System/Library/* | /usr/lib/* | @rpath/* | @loader_path/*) continue ;;
		/*)
			dbase=$(basename "$dep")
			echo "  [dylib-dep] $base: $dep -> @rpath/$dbase"
			install_name_tool -change "$dep" "@rpath/$dbase" "$dylib" || true
			;;
		esac
	done
done

echo "[STAGE 3]: Patching Mach-O files (set appropriate LC_RPATH and rewrite absolute deps)"
while IFS= read -r bin; do
	# Determine rpath relative to binary location
	case "$bin" in
	"$MACOS_DIR"/*)
		RPATH="@executable_path/../Frameworks"
		;;
	"$REL_APP_DIR"/erts-*/bin/*)
		RPATH="@executable_path/../../../../Frameworks"
		;;
	"$REL_APP_DIR"/lib/*/priv/*.so)
		RPATH="@loader_path/../../../../Frameworks"
		;;
	"$FRAMEWORKS_DIR"/*.dylib)
		RPATH="@loader_path"
		;;
	*)
		# conservative default: top-level MacOS executable path
		RPATH="@executable_path/../Frameworks"
		;;
	esac

	echo "[patch] $bin  (rpath=$RPATH)"

	# remove any previously-added known rpaths to avoid duplication
	install_name_tool -delete_rpath "@executable_path/../Frameworks" "$bin" 2>/dev/null || true
	install_name_tool -delete_rpath "@executable_path/../../../../Frameworks" "$bin" 2>/dev/null || true
	install_name_tool -delete_rpath "@loader_path/../../../../Frameworks" "$bin" 2>/dev/null || true
	install_name_tool -delete_rpath "@loader_path" "$bin" 2>/dev/null || true

	install_name_tool -add_rpath "$RPATH" "$bin" 2>/dev/null || true

	# rewrite absolute non-system deps to @rpath/<name>
	otool -L "$bin" | awk 'NR>1 {print $1}' | while read -r dep; do
		case "$dep" in
		/System/Library/* | /usr/lib/* | @rpath/* | @loader_path/*) continue ;;
		/*)
			dbase=$(basename "$dep")
			echo "  [change] $dep -> @rpath/$dbase"
			install_name_tool -change "$dep" "@rpath/$dbase" "$bin" || true
			;;
		esac
	done
done <"$MACHO_FILES"

rm -f "$MACHO_FILES"
echo "Done."
