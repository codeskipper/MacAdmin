#!/usr/bin/env zsh

# snow_lm_last_run.zsh
# Purpose: return date string / status code for last run
#
# How: Snow license manager creates and updates the following folder/file after installing when run regularly
# We'll check if the path exists and if not, return "null"
# If it exists, we'll check the content for the key "Last run", and if it doesn't exist, return "0"
# If key "Last run" exists, and if we can parse the date value string, echo to stdout as sensor output

thePath="/opt/snow/data/.hst.lg"
theKey="Last run"

if [[ -e "$thePath" ]]; then
    # The folder and file exists.
    theLine=$( grep -E "$theKey" "$thePath" )
    if [[ $? -ne 0 ]]; then
    	# could not find line with "Last Run" in file
        echo "0"
        exit 0
    fi
    theValue=$( echo $theLine | awk  -F'=' '{print $2}' )
    if [[ $? -eq 0 ]]; then
        echo "$theValue"
    else
    	# could not parse date value for Last run in file
        echo "0"
    fi
else
    # The folder and/or file does NOT exist.
    echo "null"
fi
exit 0
