#!/bin/sh

ARCHIVE_PATH="$1"

echo "===Exporting Build from $ARCHIVE_PATH==="

rm -rf "build"
mkdir "build"
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportOptionsPlist "ExportOptions.plist" -exportPath "build"

echo "===Creating DMG ==="
DMG_PATH=$(dropdmg --config-name=Coppice --destination=export build/Coppice.app)

echo "===Sending to Notarization==="
xcrun altool --notarize-app -f "$DMG_PATH" --primary-bundle-id "com.mcubedsw.coppice" -u "pilky@mcubedsw.com" -p "@keychain:Notarization" --asc-provider "MartinPilkington74170789" 

# open "$DMG_PATH"