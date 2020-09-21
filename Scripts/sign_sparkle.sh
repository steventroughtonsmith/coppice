#!/bin/sh

SPARKLE_PATH="$1"

$SPARKLE_PATH/bin/codesign_embedded_executable "Developer ID Application: M Cubed Software Ltd. (K3K39KWKBV)" XPCServices/*.xpc
$SPARKLE_PATH/bin/codesign_embedded_executable "Developer ID Application: M Cubed Software Ltd. (K3K39KWKBV)" ./Sparkle.framework/Versions/A/Resources/Autoupdate
$SPARKLE_PATH/bin/codesign_embedded_executable "Developer ID Application: M Cubed Software Ltd. (K3K39KWKBV)" ./Sparkle.framework/Versions/A/Resources/Updater.app/

echo "Signed!"