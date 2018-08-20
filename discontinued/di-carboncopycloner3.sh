#!/bin/zsh -f
# Purpose: Download and install latest version of Carbon Copy Cloner 3 (there is also a version 5! too)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-02

NAME="$0:t:r"

	# Note: This is a different location than usual to avoid conflicts with later versions of CCC
INSTALL_TO='/Applications/Carbon Copy Cloner 3.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# sparkle:version is the only version info in the feed

OS_VER=$(sw_vers -productVersion | cut -d '.' -f 1,2)

ACTUAL_OS_VERSION=$(sw_vers -productVersion | cut -d '.' -f 2)

if [[ "$OS_VER" == "" ]]
then
	echo "$NAME: Fatal error. Cannot determine operating system version. Exiting now."
	exit 1
fi

case "$OS_VER" in
	10.4|10.5)
		[[ "$USE_VERSION" = "" ]] && USE_VERSION='3'
		LATEST_VERSION="3.4.7"
		# Download CCC 3.4.7 for use on Tiger (10.4) and Leopard (10.5).
	;;

	*)
		[[ "$USE_VERSION" = "" ]] && USE_VERSION='3'
		LATEST_VERSION="3.5.7"
	;;
esac

URL=$(curl -sfL --head "https://bombich.com/software/download_ccc_update.php?v=$LATEST_VERSION" \
	| awk -F' |\r' '/^.ocation/{print $2}' )

	# If any of these are blank, we should not continue
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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null | tr -dc '[0-9]\.'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

case "$LATEST_VERSION" in
	3.4.7)

		FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.dmg"

		echo "$NAME: Downloading $URL to $FILENAME"

		curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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

			# Note that this handles the rename that we are doing to avoid potential conflicts with later versions of CCC
		echo "$NAME: Installing $MNTPNT/Carbon Copy Cloner.app to $INSTALL_TO"

		ditto --noqtn -v "$MNTPNT/Carbon Copy Cloner.app" "$INSTALL_TO" \
		&& diskutil eject "$MNTPNT"

	;;

	3.5.7)
		FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.zip"

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
		mv -vn "$UNZIP_TO/Carbon Copy Cloner.app" "$INSTALL_TO"

		EXIT="$?"

		if [[ "$EXIT" = "0" ]]
		then

			echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

		else
			echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

			exit 1
		fi

		[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

	;;

esac

exit 0
#EOF
