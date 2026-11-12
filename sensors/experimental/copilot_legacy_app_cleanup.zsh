#!/usr/bin/env zsh

# script: copilot_legacy_app_cleanup.zsh
# purpose: sensor to clear the way for the new Microsoft 365 Copilot app (pkg install, bundle ID com.microsoft.m365copilot)
#    by removing the legacy App Store "Copilot" app (bundle ID com.microsoft.copilot-mac) that lives at the
#    same path /Applications/Copilot.app, and report what was found/done.

# Why a sensor: Munki (embedded in WS1 Intelligent Hub) compares only the version of the bundle found at the
# installs path, not its bundle ID. The legacy app's CFBundleVersion sorts higher than the new app's, so Munki
# reports "already installed" and never runs the install - nor its preinstall script.
# The presumption is that this sensor is executed as root (WS1 execution context: System).

# Sensor output is the single log line for the outcome, e.g.
#   "<timestamp> [copilot_legacy_app_cleanup] Not installed"
#   "... Removed legacy <version>"       - legacy App Store app found and removed
#   "... Removed unreadable bundle"      - bundle at path had no readable bundle ID, removed
#   "... Current <bundle id> <version>"  - new app (or other bundle) present, left alone
#   "... Removal failed <bundle id>"     - rm failed (e.g. SIP/permissions)


# HARDCODED VALUES ARE SET HERE
VERSION="2026-11-12 #1"
SCRIPT="copilot_legacy_app_cleanup"

APP="/Applications/Copilot.app"
LEGACY_ID="com.microsoft.copilot-mac"


# variable and function declarations

# Get this scripts starting folder
this_script="${0:a}"
# script_path="${this_script:h}"
this_script_name="${this_script:t}"
# WS1 runs scripts/sensors from a generated temp file so the derived name is meaningless there;
# use the hardcoded SCRIPT name unless run standalone from a terminal
[[ -t 0 ]] || this_script_name="$SCRIPT"

logfile="/tmp/${this_script_name}.log"

# write timestamp + message to logfile + stdout
function log() {
    timestamp=$(date +%Y-%m-%d\ %H:%M:%S%z)
    message="$timestamp [$this_script_name] $1"
    echo "$message"
    echo "$message" >> "${logfile}"
}

# read a key from the app bundle's Info.plist, prints nothing if unreadable
function bundle_value() {
    /usr/bin/defaults read "$APP/Contents/Info" "$1" 2>/dev/null
}


# main code starts here
if [[ ! -d "$APP" ]]; then
    log "Not installed"
    exit 0
fi

id=$(bundle_value CFBundleIdentifier)
version=$(bundle_value CFBundleShortVersionString)
[[ -z "$version" ]] && version=$(bundle_value CFBundleVersion)

if [[ "$id" == "$LEGACY_ID" ]]; then
    /usr/bin/osascript -e "quit app id \"$LEGACY_ID\"" >/dev/null 2>&1
    sleep 2
    if /bin/rm -rf "$APP"; then
        /usr/sbin/pkgutil --forget "$LEGACY_ID" >/dev/null 2>&1
        log "Removed legacy ${version:-unknown}"
    else
        log "Removal failed $id"
    fi
    exit 0
fi

if [[ -z "$id" ]]; then
    if /bin/rm -rf "$APP"; then
        log "Removed unreadable bundle"
    else
        log "Removal failed unknown"
    fi
    exit 0
fi

log "Current $id ${version:-unknown}"
exit 0
