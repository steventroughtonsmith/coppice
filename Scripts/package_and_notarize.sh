#!/bin/sh

ARCHIVE_PATH="~/Library/Developer/Xcode/Archives/$1"

rm -rf "build"
mkdir "build"
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportOptionsPlist "ExportOptions.plist" -exportPath "build"

mkdir "export"
DMG_PATH=$(dropdmg --config-name=Coppice --destination=export build/Coppice.app)
rm -rf "build"

xcrun altool --notarize-app --primary-build-id "com.mcubedsw.coppice" --username "pilky@mcubedsw.com" --password "@keychain:Notarization" --file "$DMG_PATH"

open "$DMG_PATH"