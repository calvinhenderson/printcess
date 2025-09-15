#!/usr/bin/env sh
set -eu

if [ -z "$APP_BUNDLE_DIR" ] || [ ! -d "$APP_BUNDLE_DIR" ]; then
	echo "Usage: APP_BUNDLE_DIR=... $0"
	echo "APP_BUNDLE_DIR is not set or the path is not a directory."
	exit 1
fi

# Canonicalize APP_BUNDLE_DIR to handle relative paths and symlinks
APP_BUNDLE_DIR=$(cd "$APP_BUNDLE_DIR"; pwd)

MACOS_DIR="$APP_BUNDLE_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE_DIR/Contents/Resources"
FRAMEWORKS_DIR="$APP_BUNDLE_DIR/Contents/Frameworks"
REL_APP_DIR="$RESOURCES_DIR/app"

mkdir -p "$FRAMEWORKS_DIR"

# Set up temporary files for processing and ensure they are cleaned up on exit
PENDING_SCAN=$(mktemp)
PROCESSED_FILES=$(mktemp)
MACHO_FILES=$(mktemp) # This will hold the complete list of all Mach-O files

cleanup() {
    rm -f "$PENDING_SCAN" "$PROCESSED_FILES" "$MACHO_FILES"
}
trap cleanup EXIT

# --- STAGE 1: Recursively discover and copy dependencies ---
echo "[STAGE 1]: Recursively discovering and copying dependencies"

# Initial population: find all Mach-O files inside the bundle
find "$APP_BUNDLE_DIR" -type f | while read -r f; do
	# use file utility to detect Mach-O; POSIX-safe
	if file "$f" | grep -q "Mach-O"; then
		printf '%s\n' "$f" >> "$PENDING_SCAN"
		printf '%s\n' "$f" >> "$MACHO_FILES"
	fi
done

# Process files until the pending list is empty
while [ -s "$PENDING_SCAN" ]; do
    # Pop the next file from the worklist
    bin=$(head -n 1 "$PENDING_SCAN")
    tail -n +2 "$PENDING_SCAN" > "$PENDING_SCAN.tmp" && mv "$PENDING_SCAN.tmp" "$PENDING_SCAN"
    
    # Use a "seen" file to avoid processing the same file twice (handles cycles)
    if grep -qFx "$bin" "$PROCESSED_FILES"; then
        continue
    fi
    printf '%s\n' "$bin" >> "$PROCESSED_FILES"

    echo " [scan] $(basename "$bin")"

    # Get the RPATHs for this binary to resolve @rpath dependencies
    RPATHS=$(otool -l "$bin" | grep -A2 LC_RPATH | grep 'path ' | awk '{print $2}' | tr '\n' ':')
    
    # Scan the binary's dependencies
    otool -L "$bin" | awk 'NR>1 {print $1}' | while read -r dep; do
        resolved_path=""
        
        case "$dep" in
        /System/Library/* | /usr/lib/*)
            continue # ignore system dependencies
            ;;
        @rpath/*)
            dep_rel_path="${dep#@rpath/}"
            # Iterate through the binary's RPATHs to find the dependency
            IFS=':'
            for rpath_template in $RPATHS; do
                unset IFS
                bin_dir=$(dirname "$bin")
                # Expand @loader_path and @executable_path. For bundling, treating them
                # as equivalent to the binary's location is a robust heuristic.
                rpath=$(echo "$rpath_template" | sed "s#@loader_path#$bin_dir#g" | sed "s#@executable_path#$bin_dir#g")
                
                # Construct a candidate path and normalize '..' etc. in a subshell
                candidate=$( $(cd "$(dirname "$rpath/$dep_rel_path")" && pwd)/$(basename "$rpath/$dep_rel_path") 2>/dev/null || true )
                
                if [ -f "$candidate" ]; then
                    resolved_path="$candidate"
                    break # Found a match, stop searching RPATHs
                fi
                unset IFS # Reset for next loop iteration
            done
            unset IFS # Reset after loop
            ;;
        @loader_path/*)
            bin_dir=$(dirname "$bin")
            dep_rel_path="${dep#@loader_path/}"
            # Construct candidate path and normalize in a subshell
            candidate=$( $(cd "$(dirname "$bin_dir/$dep_rel_path")" && pwd)/$(basename "$bin_dir/$dep_rel_path") 2>/dev/null || true )
            if [ -f "$candidate" ]; then
                resolved_path="$candidate"
            fi
            ;;
        /*)
            # Absolute path
            if [ -f "$dep" ]; then
                resolved_path="$dep"
            fi
            ;;
        esac

        if [ -z "$resolved_path" ]; then
            continue # Could not resolve, or it was a system lib
        fi
        
        # If the dependency is outside the bundle, copy it in and add to worklist
        case "$resolved_path" in
        "$APP_BUNDLE_DIR"/*)
            continue # Already inside the bundle
            ;;
        *)
            base=$(basename "$resolved_path")
            dest="$FRAMEWORKS_DIR/$base"
            
            if [ ! -f "$dest" ]; then
                echo "  [copy] $resolved_path -> $dest"
                cp "$resolved_path" "$dest"
                chmod 755 "$dest"
                # Add the new dylib to the worklist to scan its own dependencies
                printf '%s\n' "$dest" >> "$PENDING_SCAN"
                # Also add it to the master list of files to be patched
                printf '%s\n' "$dest" >> "$MACHO_FILES"
            fi
            ;;
        esac
    done
done

# De-duplicate the final list of files to patch
sort -u -o "$MACHO_FILES" "$MACHO_FILES"

echo "[STAGE 2]: Normalizing Frameworks dylibs (set id to @rpath and ensure loader rpath)"
# For each copied dylib, set its id and add loader rpath so it can find sibling libs
for dylib in "$FRAMEWORKS_DIR"/*.dylib; do
	[ -f "$dylib" ] || continue
	base=$(basename "$dylib")
	echo "[fix-id] $base"
	install_name_tool -id "@rpath/$base" "$dylib"

	# Clean up any hardcoded RPATHs from build environments (e.g., Homebrew)
	otool -l "$dylib" | grep -A2 LC_RPATH | grep '/.*' | awk '{print $2}' | while read -r rpath; do
		install_name_tool -delete_rpath "${rpath}" "$dylib" 2>/dev/null || true
	done

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

	echo "[patch] $(basename "$bin") (rpath=$RPATH)"

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

echo "Done."
