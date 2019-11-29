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

INSTALL_TO='/Applications/Clean Text.app'

URL='https://www.apimac.com/download/CleanText.zip'

XML_FEED="https://www.apimac.com/version_checking/cleantext.xml"

echo "$NAME: the feed ($XML_FEED) is not really useful right now. No version info.\n"

curl -sfLS "$XML_FEED"

echo '\n\n'

exit 0
#EOF
