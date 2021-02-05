#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-02-05

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://downloads.meet.cam/updates/appcast.xml'

INFO=($(curl -sfLS "$XML_FEED" \
	| tr -s '\t|\n| ' ' ' \
| sed -e 's#.*<item>##g' -e 's# </item>.*##g' -e 's#> <#>\
<#g' -e 's# url=#\
url=#g' -e 's# sparkle:#\
sparkle:#g' \
	-e 's#</sparkle:minimumSystemVersion>#"#g' \
	-e 's#<sparkle:releaseNotesLink>#sparkle:releaseNotesLink="#g' \
	-e 's#</sparkle:releaseNotesLink>#"#g' \
	-e 's# length=.*##g' \
	-e 's#<sparkle:minimumSystemVersion>#sparkle:minimumSystemVersion="#' \
	| egrep 'sparkle:|^url=' \
	| sort \
	| awk -F'"' '//{print $2}'))

MINVERSION="$INFO[1]"
RELEASE_NOTES_URL="$INFO[2]"
LATEST_VERSION="$INFO[3]"
LATEST_BUILD="$INFO[4]"
URL="$INFO[5]"
# 10.15
# https://downloads.meet.cam/updates/meetcam-0.8.3-463.html
# 0.8.3
# 463
# https://downloads.meet.cam/updates/meetcam-0.8.3-463.zip

cat <<EOINPUT

MINVERSION: $MINVERSION
RELEASE_NOTES_URL: $RELEASE_NOTES_URL
LATEST_VERSION: $LATEST_VERSION
LATEST_BUILD: $LATEST_BUILD
URL: $URL

EOINPUT




exit 0
#EOF
