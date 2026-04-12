#!/usr/bin/env zsh

# script: eacs_runner.zsh
# purpose: self-service script so a user can run Erase Assistant
#     also known from Apple System Settings as Erase All Content and Settings, often shortened to EACS
#     without being the account being admin on the Mac and user does not need to know the EFI firmware password
#     that might have been set on an Intel Mac

# The presumption is that this script will be executed as root from a launch daemon
# or triggered using some self-service tool such as WorkSpace ONE Intelligent Hub.

# portions of this script were adapted from a template script for running a command as user by
# Armin Briegel - Scripting OS X - https://scriptingosx.com/2020/08/running-a-command-as-another-user/

# This script makes use of the following environment variables to help debugging script execution or deployment
# $FW_PASSWD="YourSecret"
# TIMEOUT="60"  # the timeout to wait for the user to input their password after launching Erase Assistant
# DEBUG='True' or DEBUG='False'

# HARDCODED VALUES ARE SET HERE
VERSION="2024-11-21 #1"


# variable and function declarations

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Get this scripts starting folder
this_script="${0:a}"
# script_path="${this_script:h}"
this_script_name="${this_script:t}"

logfile="/tmp/${this_script_name}.log"

# write timestamp + message to logfile + stdout
function log() {
    timestamp=$(date +%Y-%m-%d\ %H:%M:%S%z)
    message="$timestamp [$this_script_name] $1"
    echo "$message"
    echo "$message" >> "${logfile}"
}

log "The following environment exports are set for $this_script_name:"

# if env var not set, use default
if ! (( ${+TIMEOUT} )); then
    export TIMEOUT=60
fi
export | grep "TIMEOUT="

# if env var not set, use default
if ! (( ${+DEBUG} )); then
    export DEBUG="False"
fi
export | grep "DEBUG="

log "Launching script version: $VERSION"

# get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
    log "no user logged in, cannot proceed"
    exit 1
fi
# now we know a user is logged in

# get the CPU architecture to determine Mac is Intel or Apple Silicon (arm64)
arch=$(/usr/bin/arch)

# are we running on Apple Silicon or Intel
if [[ "$arch" == "i386" ]]; then
    # for Intel Mac, remove the EFI password
    # secret for Intel Mac EFI firmware password to be passed securely as environment variable from MDM/software management solution
    old_password="$FW_PASSWD"
    # new_password=""
    FWP="/usr/sbin/firmwarepasswd"

    # check if the firmware password is set
    fwp_result=$($FWP -check | /usr/bin/awk '{print $NF}')
    if [ $fwp_result = "Yes" ]; then
        # expect one-liner was inspired by this one to change EFI firmware password:
        # expect -c 'spawn '$FWP' -setpasswd; expect "Enter password:"; send -- "'$old_password'\r"; expect "Enter new password:"; send -- "'$new_password'\r"; expect "Re-enter new password:"; send -- "'$new_password'\r"; expect eof' 2>/dev/null
        # thanks https://macadmins.slack.com/archives/CGXNNJXJ9/p1700125506283679?thread_ts=1700092635.410869&cid=CGXNNJXJ9

        # delete EFI firmware password using expect
        fwp_result=$(expect -c 'spawn '$FWP' -delete; expect "Enter password:"; send -- "'$old_password'\r"; expect eof' 2>/dev/null)
        if [[ "$fwp_result" = *"Must restart before changes will take effect"* ]]; then
            log "EFI firmware password has been removed"
        else
            log "failed to remove EFI firmware password - exiting"
            exit 1
        fi
    else
        log "No EFI firmware password is set"
    fi
fi


# check admin state user account
isAdmin=$(dseditgroup -o checkmember -m $currentUser admin | awk '{print $1}')

if [[ ! $isAdmin == "yes" ]]; then
    log "making $currentUser admin"
    dseditgroup -o edit -a $currentUser admin
    sleep 5
else
    log "User is already admin"
fi


# get the current user's UID
uid=$(id -u "$currentUser")

# convenience function to run a command as the current user
# usage:
#   runAsUser command arguments...
function runAsUser() {
    if [ "$currentUser" != "loginwindow" ]; then
        launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    else
        log "no user logged in"
        # uncomment the exit command
        # to make the function exit with an error when no user is logged in
        # exit 1
    fi
}



if [[ "$DEBUG" == "True" ]]; then
    log "debugging - launching whoami as user $currentUser with uid=$uid"
    output=$(runAsUser whoami)
    log "$output"
    account_status=$(dseditgroup -o checkmember -m $currentUser admin)
    log "checking if $currentUser is admin: [$account_status]"

fi

# main code starts here
log "launching open -a /System/Library/CoreServices/Erase\ Assistant.app as user $currentUser with uid=$uid"
runAsUser open -a /System/Library/CoreServices/Erase\ Assistant.app

log "Waiting $TIMEOUT seconds for user to enter their password to open Erase Assistant"
sleep "$TIMEOUT"

## if we reach this point, Erase Assistant has not proceeded for whatever reason

log "Something went wrong running Erase Assistant, killing the app"
pkill Erase\ Assistant

# Demote user to standard user
log "Something went wrong running Erase Assistant - demoting user"
dseditgroup -o edit -d $currentUser admin

if [[ "$arch" == "i386" ]]; then
    # for Intel Mac, put the EFI password back in place
    log "Something went wrong running Erase Assistant app - putting back firmware password"
    new_password="$FW_PASSWD"

    # check if the firmware password is set - it may still report Yes if the Mac has not been restarted after it was removed
    fwp_result=$($FWP -check | /usr/bin/awk '{print $NF}')
    if [ $fwp_result = "Yes" ]; then
        old_password="$FW_PASSWD"
        # Script to change password, thanks to https://macadmins.slack.com/archives/CGXNNJXJ9/p1700125506283679?thread_ts=1700092635.410869&cid=CGXNNJXJ9
        fwp_result=$(expect -c 'spawn '$FWP' -setpasswd; expect "Enter password:"; send -- "'$old_password'\r"; expect "Enter new password:"; send -- "'$new_password'\r"; expect "Re-enter new password:"; send -- "'$new_password'\r"; expect eof' 2>/dev/null)
    else
        # set password
        fwp_result=$(expect -c 'spawn '$FWP' -setpasswd; expect "Enter new password:"; send -- "'$new_password'\r"; expect "Re-enter new password:"; send -- "'$new_password'\r"; expect eof' 2>/dev/null)
    fi

    if [[ "$fwp_result" = *"Must restart before changes will take effect"* ]]; then
        log "EFI firmware password has been set again"
    else
        log "failed to set EFI firmware password - exiting"
        exit 1
    fi
fi

exit 0
