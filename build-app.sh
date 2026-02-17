#!/bin/bash

# Build script for creating AIUsageBar.app bundle
# Usage: ./build-app.sh [--sign]

set -e

APP_NAME="AIUsageBar"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building release binary..."
swift build -c release

echo "Creating app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Copying binary..."
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/"

echo "Copying Info.plist..."
cp "Resources/Info.plist" "${CONTENTS_DIR}/"

# Replace $(EXECUTABLE_NAME) placeholder with actual name
sed -i '' 's/\$(EXECUTABLE_NAME)/'"${APP_NAME}"'/g' "${CONTENTS_DIR}/Info.plist"

echo "Creating PkgInfo..."
echo -n "APPL????" > "${CONTENTS_DIR}/PkgInfo"

echo "Copying entitlements..."
cp "Resources/${APP_NAME}.entitlements" "${CONTENTS_DIR}/"

# Handle app icon
if [ -f "Resources/AppIcon.png" ]; then
    echo "Creating app icon from PNG..."

    # Create iconset directory
    ICONSET_DIR="${RESOURCES_DIR}/${APP_NAME}.iconset"
    mkdir -p "${ICONSET_DIR}"

    # Generate all required sizes from the PNG
    sips -z 16 16     "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_16x16.png"
    sips -z 32 32     "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_16x16@2x.png"
    sips -z 32 32     "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_32x32.png"
    sips -z 64 64     "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_32x32@2x.png"
    sips -z 128 128   "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_128x128.png"
    sips -z 256 256   "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_128x128@2x.png"
    sips -z 256 256   "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_256x256.png"
    sips -z 512 512   "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_256x256@2x.png"
    sips -z 512 512   "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_512x512.png"
    sips -z 1024 1024 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_512x512@2x.png"

    # Convert to icns
    iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/${APP_NAME}.icns"

    # Cleanup
    rm -rf "${ICONSET_DIR}"

    echo "Icon created successfully."
elif [ -f "Resources/${APP_NAME}.icns" ]; then
    echo "Copying existing .icns icon..."
    cp "Resources/${APP_NAME}.icns" "${RESOURCES_DIR}/"
else
    echo "No icon found. Add Resources/AppIcon.png or Resources/${APP_NAME}.icns to include an icon."
fi

# Check for --sign flag
if [ "$1" == "--sign" ]; then
    if [ -z "$2" ]; then
        echo "Error: Please provide your Developer ID"
        echo "Usage: ./build-app.sh --sign \"Developer ID Application: Your Name (TEAMID)\""
        exit 1
    fi

    echo "Signing app with ad-hoc signature (removes Gatekeeper warnings)..."
    codesign --deep --force --verify --verbose \
        --sign "$2" \
        --options runtime \
        --entitlements "Resources/${APP_NAME}.entitlements" \
        "${APP_BUNDLE}"

    echo "Verifying signature..."
    codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"
else
    echo ""
    echo "Note: App is not code-signed."
    echo "On first launch, right-click the app and select 'Open', then click 'Open' in the dialog."
    echo "Or go to: System Settings > Privacy & Security > Open Anyway"
fi

echo ""
echo "Build complete: ${APP_BUNDLE}"
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
