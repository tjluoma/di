#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-05-20

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# @TODO - um, all of it?
# https://getoptimage.com/download/optimage-mac.zip

XML_FEED='https://getoptimage.com/appcast.xml'


exit 0
#EOF
