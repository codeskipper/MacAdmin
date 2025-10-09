#!/bin/zsh

# script: console_user_demote.zsh
# purpose: service script to demote users logged into the console of a Mac
#    typically used to make sure user accounts are type standard and privileges to be managed with another solution

# The presumption is that this script will be executed as root from a launch daemon
# or triggered using some self-service tool such as WorkSpace ONE Intelligent Hub.

# This script makes use of the following environment variables to help debugging script execution or deployment
# $DEBUG
# $EXCLUDED_ACCOUNTS="Your Account list separated by spaces"


# HARDCODED VALUES ARE SET HERE
VERSION="2025-06-17 #1"


# variable and function declarations

#export PATH=/usr/bin:/bin:/usr/sbin:/sbin

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
if ! (( ${+DEBUG} )); then
    export DEBUG="False"
fi
export | grep "DEBUG="


# if env var not set, use default
if ! (( ${+EXCLUDED_ACCOUNTS} )); then
    export EXCLUDED_ACCOUNTS="root"
fi
if [[ "$DEBUG" == "TRUE" ]]; then
    export | grep "EXCLUDED_ACCOUNTS="
fi

log "Launching script version: $VERSION"

# get the currently signed in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
    log "no user logged in, cannot proceed"
    exit 1
fi
# now we know a user is logged in


# check admin state current console user account
isAdmin=$(dseditgroup -o checkmember -m $currentUser admin | awk '{print $1}')

if [[ ! $isAdmin == "yes" ]]; then
    log "current user [$currentUser] is NOT admin, exiting script"
    exit 0
else
    log "User [$currentUser] is admin"
fi



if [[ "$DEBUG" == "True" ]]; then
    log "debugging mode is ON"
fi


if [[ "$EXCLUDED_ACCOUNTS" =~ "$currentUser" ]]; then
    log "User [$currentUser] is supposed to remain admin permanently, exiting script with code 0."
    exit 0
fi



# main code starts here
log "demoting account [$currentUser]"
dseditgroup -o edit -d $currentUser -t user admin



# check admin state current console user account again to make sure demoting worked
isAdmin=$(dseditgroup -o checkmember -m $currentUser admin | awk '{print $1}')

if [[ ! $isAdmin == "yes" ]]; then
    log "current console user [$currentUser] is NOT admin, it worked as intended, exiting script"
    exit 0
else
    log "User [$currentUser] is admin, something went wrong, exiting script with error...!"
    exit 1
fi


exit 0
