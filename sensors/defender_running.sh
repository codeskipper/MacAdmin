#!/bin/zsh

# get list of processes matching processes, return code 1 if no match
# alternately, might want to test for test for process 'wdavdaemon_unprivileged'
processList="$(pgrep 'Microsoft Defender Helper')"


# test return code, 0 means 1 or more matches found
if [[ $? -eq 1 ]]; then
    # no match, meaning critical process is NOT running
    echo "False"
else
	# no match, meaning critical process IS running
    echo "True"
fi

exit 0
