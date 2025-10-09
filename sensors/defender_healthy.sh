#!/bin/zsh

# Interrogate Microsoft Defender and return Health status detail for overall health

# use original executable instead of symlink at /usr/local/bin/mdatp to eliminate install issue
MDATP_COMMAND="/Applications/Microsoft Defender.app/Contents/Resources/Tools/wdavdaemonclient"

# If Microsoft ATP is installed, then get ATP real-time protection status
if [ -f "$MDATP_COMMAND" ]; then
    result=$("$MDATP_COMMAND" health --field healthy)
    echo "$result"
else
    echo "Not installed"
fi

exit 0
