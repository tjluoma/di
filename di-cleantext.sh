#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-11-12

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

echo "$NAME: the feed is not really useful right now"

exit 0

INSTALL_TO='/Applications/Clean Text.app'

	## This feed is not really useful right now
# curl -sfLS "https://www.apimac.com/version_checking/cleantext.xml"

URL='https://www.apimac.com/download/CleanText.zip'

exit 0
#EOF
