#!/bin/zsh -f
# Purpose: Download and install the latest version of Monolingual
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-29

NAME="$0:t:r"

INSTALL_TO='/Applications/Monolingual.app'

XML_FEED='https://ingmarstein.github.io/Monolingual/appcast.xml'

HOMEPAGE="https://ingmarstein.github.io/Monolingual/"

DOWNLOAD_PAGE="https://github.com/IngmarStein/Monolingual/releases"

SUMMARY="Monolingual is a program for removing unnecessary language resources from macOS, in order to reclaim several hundred megabytes of disk space."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# no other version info in feed
INFO=($(curl -sfL "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep 'sparkle:version=|url=' \
	| head -2 \
	| sort \
	| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO\nLATEST_VERSION: $LATEST_VERSION\nURL: $URL"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.tbz2"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	(echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
	curl -sfLS $XML_FEED \
	| sed '1,/<description>/d; /<\/description>/,$d ; s###g ;s###g ; s#<\!\[CDATA\[##; s#\]\]>##g' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Unpacking $FILENAME to $INSTALL_TO:h"

tar -x -C "$INSTALL_TO:h" -j -f "$FILENAME"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then

	echo "$NAME: Installation success."

else
	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)"

	exit 1
fi

exit 0
#EOF
