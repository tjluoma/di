#!/usr/bin/env zsh -f
# Purpose: download and install / update HandBrake CLI
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-12-22

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi

# REMOTE_FILENAME=$(curl -sfLS 'https://handbrake.fr/downloads2.php' | tr '"|=' '\012' | egrep -i '^HandBrakeCLI-.*\.dmg$')
# 	LATEST_VERSION=$(echo "$REMOTE_FILENAME:r" | tr -dc '[0-9]\.')
# 		RELEASE_NOTES_URL="https://github.com/HandBrake/HandBrake/releases/tag/$LATEST_VERSION"
#
# if [[ "$REMOTE_FILENAME" == "" ]]
# then
# 	echo "$NAME: '$REMOTE_FILENAME' is empty." >>/dev/stderr
# 	exit 1
# fi
#
# URL="https://download2.handbrake.fr/${LATEST_VERSION}/HandBrakeCLI-${LATEST_VERSION}.dmg"

FILE_PATH=$(curl -sfLS "https://github.com/HandBrake/HandBrake/releases/latest" \
			| tr '"' '\012' \
			| egrep '^/HandBrake/HandBrake/releases/download/.*/HandBrakeCLI-.*.dmg$')

URL="https://github.com${FILE_PATH}"
	REMOTE_FILENAME=$(echo "$URL:t")
	LATEST_VERSION=$(echo "$URL:r:t" | tr -dc '[0-9]\.')
		RELEASE_NOTES_URL="https://github.com/HandBrake/HandBrake/releases/tag/$LATEST_VERSION"

if (( $+commands[HandBrakeCLI] ))
then
		# this replicated 'which HandBrakeCLI'
	INSTALL_TO=$(echo =HandBrakeCLI)
	INSTALLED_VERSION=$(HandBrakeCLI --version 2>/dev/null | egrep '[0-9]' | tr -dc '[0-9]\.')

else

	INSTALL_TO='/usr/local/bin/HandBrakeCLI'
	INSTALLED_VERSION='0'

fi

INSTALL_DIR="$INSTALL_TO:h"

if [[ ! -w "$INSTALL_DIR" ]]
then

	if [[ ! -e "$INSTALL_DIR" ]]
	then
		echo "$NAME: '$INSTALL_DIR' does not exist."
	else
		echo "$NAME: '$INSTALL_DIR' exists but is not writable."
	fi

	exit 1
fi


if [[ -e "$INSTALL_TO" ]]
then

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [[ "$VERSION_COMPARE" == "0" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" \
		| sed -e '1,/<div class="markdown-body">/d' -e '/<summary>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin)

	echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nURL: ${URL}\n" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to Trash. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi

fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
