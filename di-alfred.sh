#!/bin/zsh -f
# Purpose: Download and install/update Alfred 2 or 3, depending on OS version or what's already installed
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

NAME="$0:t:r"

HOMEPAGE="https://www.alfredapp.com"

DOWNLOAD_PAGE="https://www.alfredapp.com"

SUMMARY="Alfred is an award-winning app for Mac OS X which boosts your efficiency with hotkeys, keywords, text expansion and more. Search your Mac and the web, and be more productive with custom actions to control your Mac."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

OS_VER=$(sw_vers -productVersion | cut -d '.' -f 1,2)

autoload is-at-least

is-at-least "10.9" "$OS_VER"

IS_AT_LEAST="$?"

if [[ "$IS_AT_LEAST" == "0" ]]
then
	# Can use either

	if [[ -e '/Applications/Alfred 2.app' ]]
	then
		USE_VERSION='2'
	else

		INSTALL_TO='/Applications/Alfred 3.app'

		USE_VERSION='3'

			# if you want to install beta releases
			# create a file (empty, if you like) using this file name/path:
		PREFERS_BETAS_FILE="$HOME/.config/di/alfred-prefer-betas.txt"

		if [[ -e "$PREFERS_BETAS_FILE" ]]
		then
			XML_FEED='https://www.alfredapp.com/app/update/prerelease.xml'
			NAME="$NAME (beta releases)"

		else
				## This is for official, non-beta versions
			XML_FEED='https://www.alfredapp.com/app/update/general.xml'
		fi
	fi
else
	# Can only use Alfred 2
	USE_VERSION='2'
fi

if [[ "$USE_VERSION" == "2" ]]
then

	INSTALL_TO='/Applications/Alfred 2.app'
	XML_FEED='https://cachefly.alfredapp.com/updater/info.plist'
fi

INFO=($(curl -sfL "$XML_FEED" \
	| egrep -A1 '<key>version</key>|<key>build</key>|<key>location</key>' \
	| egrep '<string>|<integer>' \
	| head -3 \
	| sort \
	| awk -F'>|<' '//{print $3}'))

LATEST_BUILD="$INFO[1]"
LATEST_VERSION="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
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

FILENAME="$HOME/Downloads/Alfred-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if [[ "$USE_VERSION" == "3" ]]
then

	RELEASE_NOTES_URL="$XML_FEED"

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION/$LATEST_BUILD:\n" ;
	curl -sfL "$RELEASE_NOTES_URL" \
	| sed "1,/^## Alfred $LATEST_VERSION/d; /^## /,\$d" ;
	echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

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
#
#EOF
