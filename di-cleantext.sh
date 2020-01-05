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

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Clean Text.app'
else
	INSTALL_TO='/Applications/Clean Text.app'
fi

HOMEPAGE='https://www.apimac.com/mac/cleantext/'

URL='https://www.apimac.com/download/CleanText.zip'

XML_FEED="https://www.apimac.com/version_checking/cleantext.xml"

echo "$NAME: the feed ($XML_FEED) is not really useful right now. No version info.\n"

curl -sfLS "$XML_FEED"

exit 0
#EOF
