#!/bin/zsh

boottime_epoch_seconds=$( /usr/sbin/sysctl -n kern.boottime | awk -F'[ ,]' '{print $4}' )

boottime_timestamp=$( date -r $boottime_epoch_seconds +%Y-%m-%d\ %H:%M:%S%z )
echo "Boottime (rfc-3339) timestamp: $boottime_timestamp"

timestamp_epoch=$( date +%s )
uptime_seconds=$(($timestamp_epoch-$boottime_epoch_seconds))
echo "Uptime in seconds: $uptime_seconds"

uptime_human=$( awk -v uptime_secs=$uptime_seconds \
    'BEGIN { seconds = uptime_secs % 60; \
    minutes = int(uptime_secs / 60 % 60); \
    hours = int(uptime_secs / 60 / 60 % 24); \
    days = int(uptime_secs / 60 / 60 / 24); \
    printf("%.0f days, %.0f hours, %.0f minutes, %.0f seconds", days, hours, minutes, seconds); \
    exit }' )
echo "Uptime as human readable: $uptime_human"

