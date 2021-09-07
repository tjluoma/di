#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-09-06

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Maestral.app"

XML_FEED='https://maestral.app/appcast.xml'

TEMPFILE="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.txt"

curl -sfLS "$XML_FEED" | awk '/<item>/{i++}i==1' >| "$TEMPFILE"







exit 0
#EOF
