#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-02-07

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi

#  curl -sfLS "https://github.com/insidegui/NoiseBuddy/releases.atom" | less



exit 0
#EOF
