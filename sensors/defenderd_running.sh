#!/bin/zsh

# test if Defender Daemon is running

# return code 1 if no match
pgrep -q wdavdaemon_unprivileged

# test return code, 0 means 1 or more matches found
if [[ $? -eq 1 ]]; then
    # no match, meaning critical process is NOT running
    echo "False"
else
	# no match, meaning critical process IS running
    echo "True"
fi

exit 0
