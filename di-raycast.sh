#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-03-15

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

# curl -sfLS "https://api.raycast.app/v2/releases/latest?build=arm&systemVersion=Version%2011.2.3%20(Build%2020D91)&version=1.9.0"
# returns '401 not authorized'

exit 0
#EOF
