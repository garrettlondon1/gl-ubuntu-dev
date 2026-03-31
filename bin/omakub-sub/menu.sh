#!/bin/bash

if [ $# -eq 0 ]; then
	SUB=$(gum choose "Theme" "Font" "Update" "Quit" --height 7 --header "" | tr '[:upper:]' '[:lower:]')
else
	SUB=$1
fi

[ -n "$SUB" ] && [ "$SUB" != "quit" ] && source $OMAKUB_PATH/bin/omakub-sub/$SUB.sh
