#!/bin/zsh -f
# Purpose: Download and install the latest version of Keyboard Maestro from <http://www.keyboardmaestro.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Keyboard Maestro.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH_APP="no"

LAUNCH_ENGINE="yes"

LATEST_VERSION_MAIN=$(curl -sfL "https://www.keyboardmaestro.com/main/" | fgrep -i '<title>' | tr -dc '[0-9]\.')

LATEST_VERSION_ALT=$(curl -sL 'https://files.stairways.com' | awk -F'"| |<' '/keyboardmaestro.*zip/{print $8}' | head -1)

[[ "$LATEST_VERSION_MAIN" = "" ]] && LATEST_VERSION_MAIN='0'

[[ "$LATEST_VERSION_ALT" = ""  ]] && LATEST_VERSION_ALT='0'

if [[ "$LATEST_VERSION_MAIN" == "$LATEST_VERSION_ALT" ]]
then
	echo "$NAME: LATEST_VERSION (identical): $LATEST_VERSION_MAIN"
	LATEST_VERSION="$LATEST_VERSION_MAIN"
else

	LATEST_VERSION_MAIN_SQUISHED=$(echo "$LATEST_VERSION_MAIN" | tr -dc '[0-9]')
	LATEST_VERSION_ALT_SQUISHED=$(echo "$LATEST_VERSION_ALT" | tr -dc '[0-9]')

	if [ "$LATEST_VERSION_MAIN_SQUISHED" -gt "$LATEST_VERSION_ALT_SQUISHED" ]
	then
		echo "$NAME: LATEST_VERSION_MAIN '$LATEST_VERSION_MAIN' is GREATER than LATEST_VERSION_ALT '$LATEST_VERSION_ALT'"
		LATEST_VERSION="$LATEST_VERSION_MAIN"

	elif [[ "$LATEST_VERSION_MAIN_SQUISHED" -lt "$LATEST_VERSION_ALT_SQUISHED" ]]
	then
		echo "$NAME: LATEST_VERSION_MAIN '$LATEST_VERSION_MAIN' is LESS than LATEST_VERSION_ALT '$LATEST_VERSION_ALT'"
		LATEST_VERSION="$LATEST_VERSION_ALT"

	else
		echo "$NAME: I don't know how we got here, but:
			LATEST_VERSION_MAIN: $LATEST_VERSION_MAIN ($LATEST_VERSION_MAIN_SQUISHED)
			LATEST_VERSION_ALT: $LATEST_VERSION_ALT ($LATEST_VERSION_ALT_SQUISHED)"

		exit 1
	fi
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

# If we get here, we _are_ outdated. Now we just need to figure out which URL to use.

URL_MAIN=$(curl -sfL --head 'https://www.keyboardmaestro.com/action/download?km-kmi-7-b3' | awk -F' |\r' '/^Location/{print $2}' | sed 's#http://#https://#g')

URL_ALT=$(curl -sfL 'https://files.stairways.com' | awk -F'"' '/keyboardmaestro.*\.zip/{print "https://files.stairways.com/"$2}' | head -1)

if [[ "$URL_ALT" == "$URL_MAIN" ]]
then
	URL="$URL_ALT"
	echo "$NAME: URL (identical): $URL"
else
	URL_ALT_NUMBERS=$(echo  "$URL_ALT:t:r"  | tr -dc '[0-9]')
	URL_MAIN_NUMBERS=$(echo "$URL_MAIN:t:r" | tr -dc '[0-9]')

	if [ "$URL_MAIN_NUMBERS" -gt "$URL_ALT_NUMBERS" ]
	then
		echo "$NAME: URL_MAIN is greater ($URL_MAIN_NUMBERS vs $URL_ALT_NUMBERS)"
		URL="$URL_MAIN"
	else
		echo "$NAME: URL_ALT is greater ($URL_ALT_NUMBERS vs $URL_MAIN_NUMBERS)"
		URL="$URL_ALT"
	fi
fi

FILENAME="$HOME/Downloads/KeyboardMaestro-${LATEST_VERSION}.zip"

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

	pgrep -q 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& osascript -e 'tell application "Keyboard Maestro Engine" to quit'

	pgrep -q 'Keyboard Maestro' \
	&& LAUNCH_APP='yes' \
	&& osascript -e 'tell application "Keyboard Maestro" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Keyboard Maestro.$INSTALLED_VERSION.$RANDOM.app"

fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then
	[[ "$LAUNCH_ENGINE" == "yes" ]]	&& open -a "${INSTALL_TO}/Contents/MacOS/Keyboard Maestro Engine.app"

	[[ "$LAUNCH_APP" == "yes" ]] 		&& open -a "${INSTALL_TO}"

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

exit 0
#EOF
