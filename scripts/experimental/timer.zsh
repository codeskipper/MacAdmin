#!/usr/bin/env zsh

# show a timestamp at the given interval, starting from a multiple of that interval after the hour, and on each interval multiple
# useful for documenting timing of events happening on screen
# endless loop, end with keyboard interrupt (^C)

# Define the desired interval in seconds (e.g., 300 for every 5 minutes) default:60
# set the environment variable before calling she script like
# export INTERVAL_SECONDS=300
if ! (( ${+INTERVAL_SECONDS} )); then
	INTERVAL_SECONDS=60
fi

# what level / how much DEBUG output is needed, default:0
# you can set the environment variable before calling she script like
# DEBUG_LEVEL=1
if ! (( ${+DEBUG_LEVEL} )); then
	DEBUG_LEVEL=0
fi

wait_interval_multiple() {
	# Get the current second of the minute
	CURRENT_SECOND=$(date +"%S")

	# Get the current minute of the hour
	CURRENT_MINUTE=$(date +"%M")

	# Calculate the total seconds past the hour
	TOTAL_SECONDS_PAST_HOUR=$(( CURRENT_MINUTE * 60 + CURRENT_SECOND ))

	# Calculate the remainder when dividing by the interval
	REMAINDER=$(( TOTAL_SECONDS_PAST_HOUR % INTERVAL_SECONDS ))

	# Calculate the time to sleep until the next multiple
	if [ "$REMAINDER" -eq 0 ]; then
		# If already at a multiple, wait for a full interval
		SLEEP_TIME="$INTERVAL_SECONDS"
	else
		# Otherwise, wait for the remaining time to reach the next multiple
		SLEEP_TIME=$(( INTERVAL_SECONDS - REMAINDER ))
	fi

	if [ "$DEBUG_LEVEL" -ge 1 ]; then
		echo "Current time: $(date +"%H:%M:%S")"
		echo "Waiting for $SLEEP_TIME seconds until the next multiple of $INTERVAL_SECONDS seconds past the hour."
	fi

	sleep "$SLEEP_TIME"

	if [ "$DEBUG_LEVEL" -ge 1 ]; then
		echo "Resuming script at: $(date +"%H:%M:%S")"
	fi
}


# main routine
wait_interval_multiple

clear

while true; do
	TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S%z)
	echo "[$TIMESTAMP]"
	if [ "$DEBUG_LEVEL" -ge 1 ]; then
		echo "All work and no play makes Jack a dull boy...😵"
		say "I just can't get enough"
	fi
	wait_interval_multiple
done
