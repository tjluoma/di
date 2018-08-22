#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-22

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi


DOWNLOAD = "http://shine.basilsalad.com/download.php?id=1"

XML_FEED="https://shine.basilsalad.com/appcast.php?id=1"

#	@TODO - finish once the site is back online

exit 0
#EOF
