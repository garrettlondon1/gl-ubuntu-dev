#!/bin/bash

CHOICES=(
	"LazyGit       TUI for Git"
	"LazyDocker    TUI for Docker"
	"Zellij        Adds panes, tabs, and sessions to the terminal"
	"<< Back       "
)

CHOICE=$(gum choose "${CHOICES[@]}" --height 7 --header "Update manually-managed applications")

if [[ "$CHOICE" == "<< Back"* ]] || [[ -z "$CHOICE" ]]; then
	echo ""
else
	INSTALLER=$(echo "$CHOICE" | awk -F ' {2,}' '{print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
	INSTALLER_FILE="$OMAKUB_PATH/install/terminal/app-$INSTALLER.sh"
	source $INSTALLER_FILE && gum spin --spinner globe --title "Update completed!" -- sleep 3
fi

clear
source $OMAKUB_PATH/bin/omakub
