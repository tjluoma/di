#!/bin/zsh -f
# Purpose: Install Bartender 2 or 3 depending on OS version or what's installed already
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# Bartender 2 cannot control system items in macOS High Sierra

OS_VER=$(sw_vers -productVersion | cut -d '.' -f 1,2)

autoload is-at-least

is-at-least "10.13" "$OS_VER"

IS_AT_LEAST="$?"

if [[ "$IS_AT_LEAST" == "0" ]]
then
	# Can use either

	if [[ -e "/Applications/Bartender 2.app" ]]
	then
		USE_VERSION='2'
	else
		USE_VERSION='3'

		INSTALL_TO='/Applications/Bartender 3.app'

			# if you want to install beta releases
			# create a file (empty, if you like) using this file name/path:
		PREFERS_BETAS_FILE="$HOME/.config/di/bartender3-prefer-betas.txt"

		if [[ -e "$PREFERS_BETAS_FILE" ]]
		then
			NAME="$NAME (beta releases)"

				# Reports itself as 'http://macbartender.com/B2/updates/TestAppcast.xml'
			XML_FEED='https://www.macbartender.com/B2/updates/TestUpdates.php'

		else
				# This is for non-beta
				# Feed reports itself as 'http://macbartender.com/B2/updates/Appcast.xml'
				# which is weird because it's for Bartender 3, not 2. But OK.
			XML_FEED='https://www.macbartender.com/B2/updates/updatesB3.php'
		fi

		INFO=($(curl -sSfL "${XML_FEED}" \
				| tr -s ' ' '\012' \
				| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
				| tail -3 \
				| sort \
				| awk -F'"' '/^/{print $2}'))

			# "Sparkle" will always come before "url" because of "sort"
		LATEST_VERSION="$INFO[1]"
		LATEST_BUILD="$INFO[2]"
		URL="$INFO[3]"

	fi

else
	# Can only use 2

	USE_VERSION='2'

fi

if [[ "$USE_VERSION" == "2" ]]
then
	XML_FEED='https://www.macbartender.com/B2/updates/updates.php'

	IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
					| fgrep 'https://macbartender.com/B2/updates/2' \
					| egrep 'sparkle:version|sparkle:shortVersionString=|url=' \
					| tail -1 \
					| sort ))

	URL=$(echo "$INFO" | sed 's#.*https://#https://#g; s#.zip".*#.zip#g;')

	LATEST_VERSION=$(echo "$INFO" | sed 's#.*sparkle:shortVersionString="##g; s#".*##g; ')

	LATEST_BUILD=$(echo "$INFO" | sed 's#.*sparkle:version="##g; s#".*##g;')

	INSTALL_TO="/Applications/Bartender 2.app"

fi

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

if [[ "$USE_VERSION" == "3" ]]
then

	RELEASE_NOTES_URL=`curl -sfL "$XML_FEED" | awk -F'>|<' '/sparkle:releaseNotesLink/{print $3}' | tail -1`

		# lynx can parse the HTML just fine, but its output is sort of ugly,
		# so we'll use html2text if it's available
	if (( $+commands[html2text] ))
	then

		echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n"

		curl -sfL "${RELEASE_NOTES_URL}" | html2text

		echo "\nSource: ${RELEASE_NOTES_URL}"

	elif (( $+commands[lynx] ))
	then

		echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n"

		lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL"

		echo "\nSource: ${RELEASE_NOTES_URL}"
	fi
fi

FILENAME="$HOME/Downloads/Bartender-${LATEST_VERSION}_${LATEST_BUILD}.zip"


echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

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