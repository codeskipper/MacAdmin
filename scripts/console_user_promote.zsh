#!/bin/zsh

# script: console_user_promote.zsh
# purpose: service script to promote users logged into the console of a Mac
#    typically used for troubleshooting purpose only

# The presumption is that this script will be executed as root from a launch daemon
# or triggered using some self-service tool such as WorkSpace ONE Intelligent Hub.

# This script makes use of the following environment variables to help debugging script execution or deployment
# $DEBUG


# HARDCODED VALUES ARE SET HERE
VERSION="2025-06-18 #1"


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
    log "current user [$currentUser] NOT admin, promoting"
    dseditgroup -o edit -a $currentUser -t user admin
else
    log "User [$currentUser] is admin, exiting"
fi


exit 0
