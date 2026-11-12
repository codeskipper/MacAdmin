#!/usr/bin/env zsh

# script: copilot_legacy_app_cleanup.zsh
# purpose: sensor to clear the way for the new Microsoft 365 Copilot app (pkg install, bundle ID com.microsoft.m365copilot)
#    by removing the legacy App Store "Copilot" app (bundle ID com.microsoft.copilot-mac) that lives at the
#    same path /Applications/Copilot.app, and report what was found/done.

# Why a sensor: Munki (embedded in WS1 Intelligent Hub) compares only the version of the bundle found at the
# installs path, not its bundle ID. The legacy app's CFBundleVersion sorts higher than the new app's, so Munki
# reports "already installed" and never runs the install - nor its preinstall script.
# The presumption is that this sensor is executed as root (WS1 execution context: System).

# Sensor output is the single outcome line, e.g.
#   "Not installed"
#   "Removed legacy version <version>"          - legacy App Store app found and removed (first run only)
#   "Removed unreadable bundle <path>"          - bundle at path had no readable bundle ID, removed
#   "Current version: <bundle id> <version>"    - new app (or other bundle) present, left alone
#   "Removal failed, app-id <bundle id>"        - rm failed (e.g. SIP/permissions)
# Once a removal has happened it is recorded in MARKER and every later report is prefixed with
#   "Removed legacy version <version> on <date>; " so the sensor value stays countable, e.g. in an
# Intelligence report filtered on sensor value starting with "Removed legacy".


# HARDCODED VALUES ARE SET HERE
VERSION="2026-11-12 #2"
SCRIPT="copilot_legacy_app_cleanup"

APP="/Applications/Copilot.app"
LEGACY_ID="com.microsoft.copilot-mac"

# Persists the fact that a legacy app was removed, across sensor runs. This enables the sensor to report the removal once and then keep reporting that fact in later runs, so the sensor value stays countable in Intelligence.
MARKER="/var/db/${SCRIPT}.removed"


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
    # message="$timestamp [$this_script_name] $1"
    message="$timestamp - $1"
    echo "$message" >> "${logfile}"
		echo "$1"
}

# read a key from the app bundle's Info.plist, prints nothing if unreadable
function bundle_value() {
    /usr/bin/defaults read "$APP/Contents/Info" "$1" 2>/dev/null
}


# main code starts here
# the sensor runs repeatedly; the removal happens once. Persist that fact in a marker file and
# prepend it to every later report so the sensor value stays countable in Intelligence
removed_prefix=""
if [[ -f "$MARKER" ]]; then
    removed_prefix="Removed legacy $(<"$MARKER"); "
fi

# record the removal in the marker file: "<version> on <date>"
function mark_removed() {
    print -r -- "$1 on $(date +%Y-%m-%d)" > "$MARKER"
    removed_prefix="Removed legacy $1 on $(date +%Y-%m-%d); "
}

if [[ ! -d "$APP" ]]; then
    log "${removed_prefix}Not installed"
    exit 0
fi

id=$(bundle_value CFBundleIdentifier)
version=$(bundle_value CFBundleShortVersionString)
[[ -z "$version" ]] && version=$(bundle_value CFBundleVersion)

if [[ "$id" == "$LEGACY_ID" ]]; then
		# graceful quit of the legacy app before removing it, in case it's running, will only work if the app is running in the current user context, not root
    /usr/bin/osascript -e "quit app id \"$LEGACY_ID\"" >/dev/null 2>&1
    sleep 2

    if /bin/rm -rf "$APP"; then
        /usr/sbin/pkgutil --forget "$LEGACY_ID" >/dev/null 2>&1
        mark_removed "version ${version:-unknown}"
        log "Removed legacy version ${version:-unknown}"
    else
        log "${removed_prefix}Removal failed, app-id $id"
    fi
    exit 0
fi

if [[ -z "$id" ]]; then
    if /bin/rm -rf "$APP"; then
        mark_removed "unreadable bundle"
        log "Removed unreadable bundle $APP"
    else
        log "${removed_prefix}Removal failed, reason unknown"
    fi
    exit 0
fi

log "${removed_prefix}Current version: $id ${version:-unknown}"
exit 0
