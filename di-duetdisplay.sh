#!/bin/zsh -f
# Purpose: Download and install the latest version of Duet Display
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-12

NAME="$0:t:r"

INSTALL_TO='/Applications/Duet.app'

HOMEPAGE="https://www.duetdisplay.com"

DOWNLOAD_PAGE="https://www.duetdisplay.com/#download"

SUMMARY="Turn your iPad into an extra display."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# XML_FEED='http://updates.duetdisplay.com/checkMacUpdates'
### 2018-12-15 - this feed does not seem to have the latest version either. It ends with '1.7.1.4'
## 				 Actual latest version is 2.0.3.8
## This one is even older
##   XML_FEED='https://updates.devmate.com/com.kairos.duet.xml'
##
# INFO=($(curl -sfL "$XML_FEED" \
# 		| tr -s ' ' '\012' \
# 		| egrep 'sparkle:version=|url=' \
# 		| head -2 \
# 		| sort \
# 		| awk -F'"' '/^/{print $2}'))

## https://duet.nyc3.cdn.digitaloceanspaces.com/Mac/2_0/duet-2-0-5-0.zip

URL=$(curl --fail --silent --location --head "https://www.duetdisplay.com/mac/" \
		| awk -F' ' '/^Location: /{print $2}' \
		| tail -1 \
		| tr -d '\r')

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#duet-##g; s#-#.#g')

	## "Sparkle" will always come before "url" because of "sort"
# LATEST_VERSION="$INFO[1]"
# URL="$INFO[2]"
#
# if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
# then
# 	echo "$NAME: Error: bad data received:
# 	INFO: $INFO
# 	LATEST_VERSION: $LATEST_VERSION
# 	URL: $URL
# 	"
#
# 	exit 1
# fi

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

# if (( $+commands[lynx] ))
# then
#
# 	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ${LATEST_VERSION}: " ;
# 		curl -sfLS "$XML_FEED" \
# 		| sed 	-e '1,/<item>/d; /<\/item>/,$d' \
# 				-e '1,/<description>/d; /<\/description>/,$d' \
# 				-e 's#\]\]\>##g ; s#<\!\[CDATA\[##g' \
# 		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin) \
# 	| tee -a "$FILENAME:r.txt"
#
# fi

echo "$NAME: Downloading $URL to $FILENAME"

	# Note the special '-H "Accept-Encoding: gzip,deflate"' otherwise you'll get a 404
curl -H "Accept-Encoding: gzip,deflate" --continue-at - --fail --location --output "$FILENAME" "$URL"

[[ ! -e "$FILENAME" ]] && echo "$NAME: No file found at $FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
		# Note that '-i' to pgrep
	pgrep -ixq "Duet" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Duet" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Duet.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installed/updated $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi


exit 0
#EOF
