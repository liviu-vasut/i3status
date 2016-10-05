#!/bin/bash

# Description: alternative implementation of the i3status using pure bash. The script reads pairs of key-values from
# standard input and writes the status json to standard output. Each key is a module name and each value is
# the text to be shown.
#
# Features:
# - colors can be configured for each item/module
# - colors can be set at runtime based on the text content by adding custom functions
# - multiple values can be updated but the i3 status bar is only updated once
#
# Example usages:
# 1) use a file as input, for example /tmp/status.txt
#   - in i3 config:
#     set $statusfile "/tmp/status.txt"
#     bar {
#       status_command touch $statusfile && tail -f $statusfile 2>/dev/null | ~/bin/i3status.sh
#     }
#   - a cron job can be set to write the time to the input stream of the script like this:
#     * * * * * /usr/bin/date "+clock \%Y-\%m-\%d \%H:\%M" > /tmp/status.txt
#
# 2) listening on a port (one could receive status updates from local processes and/or a remote service)
#   - in i3 config:
#     bar {
#       status_command ncat -k --recv-only -l 3333 | ~/bin/i3status.sh
#     }
#   - a cron job can be set to write the time to the input stream of the script like this:
#     * * * * * /usr/bin/date "+clock \%Y-\%m-\%d \%H:\%M" | ncat localhost 3333
#   - or, from a remote host:
#     echo -e "state\tRunning" | ncat mydesktop 3333

CONFIG=.config/i3/i3statusrc

declare -a order
declare -A colors
declare -A renderers
declare -A values

lineSeparator="";

function usage(){
	cat << EOF
	$0 [-c configfile] [-h]
		-h		show this help and quit
		-c configfile	use a different config file than the default ($CONFIG)
				following is an example config file:

				# configuration file for i3status.sh

				# you can define functions for conditionally coloring items by writing them here and then referencing their names instead of a color
				# each of these functions will be called with an argument, the text of the item, and should return a color name or "default"
				# for example, we define this function:
				# function day_or_night(){
				# 	# assuming the input is something like "10:25 AM" or "02:43 PM" this will return white for morning AM and black for PM
				# 	[[ "\$1" =~ "AM" ]] && echo "#ffffff" || echo "#000000";
				# }
				# then we use it for color
				# color "clock" "day_or_night"


				# set colors for each item in order from left to right
				# colors are #RGB, #RRGGBB, 'default' or a function (see above)
				# items not present in this list will be appended to the left of the status bar with the default color
				color "project" "default";
				color "task" "#00ff00";
				color "time" "#cccccc";
				color "state" "stateColor";
				color "clock" "default";


				# set which item will trigger an update of the status bar
				# if "all" is set the status bar is updated on any item change
				# this allows sending changes in one batch and only update once

				#renderOn "all";
				renderOn "clock";
				renderOn "state";

EOF
}

function color(){
	if [[ $# -ne 2 ]]; then
		echo "Invlid syntax: color should take 2 arguments. Got $@";
		exit 1;
	fi
	order+=( $1 );
	colors["$1"]="$2";
}

function renderOn(){
	if [[ -z "$1" ]]; then
		echo "Invalid syntax: renderOn should take 1 parameter. Got $@";
		exit 2;
	fi
	renderers["$1"]=1;
}

function render(){
	echo -n "$lineSeparator[";
	lineSeparator=",";

	separator="";
	for i in ${order[@]}; do
		echo -en "$separator{ \"full_text\": \"${values[$i]}\"";
		clr="${colors[$i]}";
		if [ -n "$clr" ] && [ "$clr" != "default" ] ; then
			if [ -n "$(type -t $clr)" ] && [ "$(type -t $clr)" = function ]; then
				clr=$($clr ${values[$i]});
			fi
			[ -n "$clr" ] && [ "$clr" != "default" ] && echo -n ", \"color\": \"$clr\"";
		fi
		echo -n "}";
		separator=",";
	done

	echo -n "]";
}

while getopts "c:h" OPTION
do
	case $OPTION in
		c)
			CONFIG=${OPTARG};
			;;
		h)
			usage
			exit 0
			;;
		?)
			echo "invalid option";
			usage
			exit 1
			;;
	esac
done

if [[ -f "$CONFIG" ]]; then
	. "$CONFIG"
else
	echo "$CONFIG does not exist."
	exit 3;
fi

echo "{\"version\":1}";
echo "[";

while IFS="	" read -r -a line; do
	if [[ ${#line[@]} -eq 2 ]] && [[ ${colors["${line[0]}"]} ]]; then
		values["${line[0]}"]="${line[1]}";
		if [[ ${renderers["all"]} ]] || [[ ${renderers["${line[0]}"]} ]]; then
			render;
		fi
	fi
done

echo "]";

