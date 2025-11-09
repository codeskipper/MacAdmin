#!/bin/sh


# This script will help set privileges to allow ARD / screen sharing for the Mac console user only
# SSH will be allowed to ALL user accounts
# thanks to https://community.jamf.com/general-discussions-2/dealing-w-screen-sharing-on-macos-10-14-and-10-15-13781?postid=93937#post93937
# NB - this script must be run as root and AFTER sending the EnableRemoteDesktop MDM command as described in https://macops.ca/managing-screen-sharing-in-monterey-12.1/

# get the currently signed in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
    log "no user logged in, cannot proceed"
    exit 1
fi
# now we know a user is logged in

# Thanks to
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -targetdisk / -activate -configure -clientopts -setmenuextra -menuextra no
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -targetdisk / -configure -users "$currentUser" -access -on -privs -all
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -targetdisk / -configure -allowAccessFor -specifiedUsers -privs -all
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -targetdisk / -restart -agent -menu
/usr/sbin/systemsetup -setremotelogin on
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -config -clientopts -setmenuextra -menuextra no
exit 0
