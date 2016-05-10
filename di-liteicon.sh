#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-10

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='http://www.freemacsoft.net/liteicon/updates.xml'

# @TODO - finish




exit 0
#EOF
