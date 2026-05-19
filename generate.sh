#!/bin/bash
set -e

xcodegen generate

# Patch the project file format version to be compatible with Xcode 15.x
# Newer XcodeGen defaults to Xcode 16 format (objectVersion 77); Xcode 15 uses 60.
PBXPROJ="Ukraily.xcodeproj/project.pbxproj"
if [ -f "$PBXPROJ" ]; then
    sed -i '' 's/objectVersion = [0-9]*;/objectVersion = 60;/' "$PBXPROJ"
    echo "Patched objectVersion to 60 (Xcode 15.x compatible)"
fi
