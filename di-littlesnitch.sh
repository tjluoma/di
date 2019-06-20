#!/bin/zsh -f
# Purpose: Download and install the latest version of LittleSnitch
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-25

NAME="$0:t:r"

INSTALL_TO='/Applications/Little Snitch Configuration.app'

HOMEPAGE="https://www.obdev.at/products/littlesnitch/index.html"

DOWNLOAD_PAGE="https://www.obdev.at/products/littlesnitch/download.html"

SUMMARY="As soon as you’re connected to the Internet, applications can potentially send whatever they want to wherever they want. Most often they do this to your benefit. But sometimes, like in case of tracking software, trojans or other malware, they don’t. But you don’t notice anything, because all of this happens invisibly under the hood. Little Snitch makes these Internet connections visible and puts you back in control."

	# if you want to install beta releases
	# create a file (empty, if you like) using this file name/path:
PREFERS_BETAS_FILE="$HOME/.config/di/prefers/littlesnitch-betas.txt"

if [[ -e "$PREFERS_BETAS_FILE" ]]
then
		# This is for betas
	HEAD_OR_TAIL='tail'
	NAME="$NAME (beta releases)"
else
		## This is for official, non-beta versions
	HEAD_OR_TAIL='head'
fi

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED="https://sw-update.obdev.at/update-feeds/littlesnitch4.plist"

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep -A1 "<key>ReleaseNotesURL</key>" \
	| awk -F'>|<' '/string/{print $3}' \
	| ${HEAD_OR_TAIL} -1)

INFO=($(curl -sfL "$XML_FEED" \
		| egrep -A1 'BundleShortVersionString|BundleVersion|DownloadURL' \
		| fgrep '<string>' \
		| ${HEAD_OR_TAIL} -3 \
		| sort \
		| sed 's#.*<string>##g; s#</string>##g'))

LATEST_VERSION="$INFO[1]"

LATEST_BUILD="$INFO[2]"

URL="$INFO[3]"

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/LittleSnitch-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes:" ;
	lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ) \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

	# Unfortunately, the installer _requires_ human interaction, so we can't automate that part.
	# ¯\_(ツ)_/¯
	# Fortunately it will handle moving the existing installation, etc
	# so that's handy

open "$MNTPNT/Little Snitch Installer.app"

exit 0
#EOF
