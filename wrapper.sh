#!/bin/bash

# This script switches to the scene called "Buddy Screen" when $SSH_ORIGINAL_COMMAND is "buddy", 
# and switches to a scene called "Braekpo1nt Screen" when $SSH_ORIGINAL_COMMAND is "braekpo1nt".
# Any other values of $SSH_ORIGINAL_COMMAND are ignored.

# $SSH_ORIGINAL_COMMAND is provded by the ssh service. It's the portion after the ip
# address of your ssh request. For example:
# ssh myuser@ip "buddy"
# results in $SSH_ORIGINAL_COMMAND=="buddy"

# This script makes use of obs-cmd: https://github.com/grigio/obs-cmd
# It makes calls to OBS Websocket easy by allowing you to specify 
# the host, port, and password, followed by your instruction in a single line.

# Notice how I'm not using $SSH_ORIGINAL_COMMAND as the actual scene name. This is because that would potentially allow the Client to arbitrarily switch to any scene they wanted. 

# Protect against arbitrary code execution through code injection
# Get the length of SSH_ORIGINAL_COMMAND
command_length=${#SSH_ORIGINAL_COMMAND}
# Check if the length is greater than 10 (the largest of my options below is 10 characters)
if (( $command_length > 10 )); then
    echo "Error: SSH_ORIGINAL_COMMAND size exceeds 4 characters (passed in option is too long)"
    exit 1
fi


case "$SSH_ORIGINAL_COMMAND" in
    "buddy")
        # $OBSWS_HOST, $OBSWS_HOST, and $OBSWS_HOST are defined in ~/.bashrc (at the top before any other lines) but you can hard-code them if you want
        obs-cmd -w obsws://$OBSWS_HOST:$OBSWS_PORT/$OBSWS_PASSWORD scene "" "Buddy Screen"
        ;;
    "braekpo1nt")
        obs-cmd -w obsws://$OBSWS_HOST:$OBSWS_PORT/$OBSWS_PASSWORD scene "" "Braekpo1nt Screen"
        ;;
    # add more cases if you want more options
    *)
        echo "Unrecognized option"
        exit 1
        ;;
esac
