#!/usr/bin/env zsh -f
# Purpose: 	Download and install Screens 4
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-08-21 ; 2019-11-15
# Verified:	2025-02-23 [version 5 is Mac App Store only and a subscription]

NAME="$0:t:r"

HOMEPAGE="https://edovia.com/screens-mac/"

DOWNLOAD_PAGE="https://dl.devmate.com/com.edovia.screens4.mac/Screens4.dmg"

SUMMARY="Control any computer from your Mac from anywhere in the world."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Screens 4.app'

XML_FEED="https://updates.edovia.com/com.edovia.screens4.mac/appcast.xml"

ITUNES_URL='apps.apple.com/us/app/screens-4/id1224268771'

INFO=($(curl -sfL "${XML_FEED}" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
		| head -3 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = ""  -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO\nLATEST_VERSION: $LATEST_VERSION\nURL: $URL"
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
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."

		if [[ "$ITUNES_URL" != "" ]]
		then
			echo "	See <https://$ITUNES_URL?mt=12> or"
			echo "	<macappstore://$ITUNES_URL>"
		fi

		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

	####################################################################################
	####################################################################################
	##
	## Hard-coding 'Screens' into $FILENAME because otherwise we end up with filenames like:
	## 		~/Downloads/Screens 4-4.5.7.zip
	## instead of
	## 		~/Downloads/Screens-4.5.7.zip
	## which is clearly superior.
	##
FILENAME="$HOME/Downloads/Screens-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	## 2020-02-06 - the release notes are now in the XML_FEED itself, not a separate URL

	RELEASE_NOTES=$(curl -sfLS "$XML_FEED" \
		| sed '1,/\[CDATA\[/d; /\]\]/,$d' \
		| lynx -dump -nomargins -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist)

	echo "${RELEASE_NOTES}\n\nURL: $URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"
		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0

#EOF
