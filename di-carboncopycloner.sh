#!/usr/bin/env zsh -f
# Purpose: Download/Install/Upgrade Carbon Copy Cloner version 3, 4, or 5, depending on OS and what's installed.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

NAME="$0:t:r"

INSTALL_TO="/Applications/Carbon Copy Cloner.app"

HOMEPAGE="https://bombich.com"

DOWNLOAD_PAGE="https://bombich.com/download"

SUMMARY="The first bootable backup solution for the Mac is better than ever."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

autoload is-at-least

USE_VERSION=''

if [[ -e "$INSTALL_TO" ]]
then
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | sed 's#\\u0192##g')

	USE_VERSION=$(echo "$INSTALLED_VERSION" | cut -d '.' -f 1)

else
	INSTALLED_VERSION='0'
fi

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d '.' -f 1,2)

ACTUAL_OS_VERSION=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d '.' -f 2)

if [[ "$OS_VER" == "" ]]
then
	echo "$NAME: Fatal error. Cannot determine operating system version. Exiting now."
	exit 1
fi

case "$OS_VER" in
	10.0|10.1|10.2|10.3)
		echo "$NAME: CarbonCopyCloner is not available for $OS_VER."
		exit 1
	;;

	10.4|10.5)
		[[ "$USE_VERSION" = "" ]] && USE_VERSION='3'
		LATEST_VERSION="3.4.7"
		# Download CCC 3.4.7 for use on Tiger (10.4) and Leopard (10.5).
	;;

	10.6|10.7)
		[[ "$USE_VERSION" = "" ]] && USE_VERSION='3'
		LATEST_VERSION="3.5.7"
		# Download CCC 3.5.7 for use on Snow Leopard (10.6) and Lion (10.7).
	;;

	10.8|10.9)
		[[ "$USE_VERSION" = "" ]] && USE_VERSION='4'
		LATEST_VERSION="4.1.23"
	;;

	*)

		if [ "$ACTUAL_OS_VERSION" -ge "14" -a "$USE_VERSION" -lt "5" -a "$INSTALLED_VERSION" != "0" ]
		then
			echo "$NAME: You have version $INSTALLED_VERSION installed, but MacOS $OS_VER requires Carbon Copy Cloner version 5."
			echo "	This script won't install version 5 over version 4, since it is a paid upgrade, but you should see <https://bombich.com/store/upgrade>"
			echo "	to find out if you are eligible for upgrade pricing. Cannot continue, exiting now."

			exit 1
		fi
	;;
esac

if [ "$USE_VERSION" != "" -a "$LATEST_VERSION" = "" ]
then
	if [ "$USE_VERSION" = "3" ]
	then
		LATEST_VERSION="3.5.7"
	elif [ "$USE_VERSION" = "4" ]
	then
		LATEST_VERSION="4.1.23"
	fi
fi

if [ "$USE_VERSION" = "3" ]
then
	URL=$(curl -sfL --head "https://bombich.com/software/download_ccc_update.php?v=$LATEST_VERSION" \
		| awk -F' |\r' '/^.ocation/{print $2}' )

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	AT_LEAST_EXIT="$?"

	if [[ "$AT_LEAST_EXIT" = "0" ]]
	then
		echo "$NAME: Up-To-Date* ($INSTALLED_VERSION/$LATEST_VERSION)"
		echo "	* well, version 5 is now available, but you have the most recent version of v3 installed"
		exit 0
	fi

	echo "$NAME: Outdated (Installed: $INSTALLED_VERSION vs Latest: $LATEST_VERSION)"

	if [ "$LATEST_VERSION" = "3.4.7" ]
	then
		FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.dmg"

		echo "$NAME: Downloading '$URL' to '$FILENAME':"

		curl --continue-at - --fail --location --output "$FILENAME" "$URL"

		EXIT="$?"

			## exit 22 means 'the file was already fully downloaded'
		[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

		[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

		[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

		echo "$NAME: Mounting $FILENAME:"

		MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
			| fgrep -A 1 '<key>mount-point</key>' \
			| tail -1 \
			| sed 's#</string>.*##g ; s#.*<string>##g')

		if [[ "$MNTPNT" == "" ]]
		then
			echo "$NAME: MNTPNT is empty"
			exit 1
		fi

		if [[ -e "$INSTALL_TO" ]]
		then
				# move installed version to trash
			mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}.app"
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

		echo "$NAME: Unmounting $MNTPNT:"

		diskutil eject "$MNTPNT"

		exit 0
	else
		# If we get here we are using 3.5.7 which is a .zip
		FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.zip"

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

			echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

			mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

			EXIT="$?"

			if [[ "$EXIT" != "0" ]]
			then

				echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

				exit 1
			fi
		fi

		echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

			# Move the file out of the folder
		mv -n "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

		EXIT="$?"

		if [[ "$EXIT" = "0" ]]
		then

			echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

			exit 0

		else
			echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

			exit 1
		fi

	fi # 3.4.7 or 3.5.7?

elif [ "$USE_VERSION" = "4" ]
then
	URL=$(curl -sfL --head "https://bombich.com/software/download_ccc.php?v=4.1.23.4644" \
		| awk -F' |\r' '/^.ocation/{print $2}' )

	LATEST_VERSION="4.1.23"

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	AT_LEAST_EXIT="$?"

	if [[ "$AT_LEAST_EXIT" = "0" ]]
	then
		echo "$NAME: Up-To-Date* ($INSTALLED_VERSION/$LATEST_VERSION)"
		echo "	* well, version 5 is now available, but you have the most recent version of v4 installed"

		exit 0
	fi

	echo "$NAME: Outdated (Installed: $INSTALLED_VERSION vs Latest: $LATEST_VERSION)"

	FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.zip"

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
		echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

		mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

		EXIT="$?"

		if [[ "$EXIT" != "0" ]]
		then

			echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

			exit 1
		fi
	fi

	echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

		# Move the file out of the folder
	mv -n "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

	EXIT="$?"

	if [[ "$EXIT" = "0" ]]
	then

		echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

		exit 0

	else
		echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

		exit 1
	fi

else
	# If we get here, we should use version 5

		# if you want to install beta releases
		# create a file (empty, if you like) using this file name/path:
	PREFERS_BETAS_FILE="$HOME/.config/di/carboncopycloner-prefer-betas.txt"

	if [[ -e "$PREFERS_BETAS_FILE" ]]
	then
		HEAD_OR_TAIL='tail'
		NAME="$NAME (beta releases)"
	else
			## This is for official, non-beta versions
		HEAD_OR_TAIL='head'
	fi

		## NOTE: If nothing is installed, we need to pretend we have at least version 5
	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '5.0.0'`

		## NOTE: If nothing is installed, we need to pretend we have at least version 5000
	INSTALLED_BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '5000'`

	OS_MINOR=`SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f 2`

	OS_BUGFIX=`SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f 3`

	XML_FEED="https://bombich.com/software/updates/ccc.php?os_minor=$OS_MINOR&os_bugfix=$OS_BUGFIX&ccc=$INSTALLED_BUILD&beta=0&locale=en"

	INFO=($(curl -sfL "$XML_FEED" \
			| egrep '"(version|build|downloadURL)":' \
			| ${HEAD_OR_TAIL} -3 \
			| tr -d ',|"' \
			| sort ))

	# sort gives us: build vs downloadURL vs version with each field being followed by the corresponding value
	LATEST_BUILD="$INFO[2]"
	URL="$INFO[4]"
	LATEST_VERSION="$INFO[6]"

	# If any of these are blank, we should not continue
	if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$LATEST_BUILD" = "" ]
	then
		echo "$NAME: Error: bad data received from ${XML_FEED}\n\tINFO: $INFO\n\tURL: $URL\n\tLATEST_VERSION: $LATEST_VERSION\n\tLATEST_BUILD: $LATEST_BUILD\n"
		exit 1
	fi

	if [[ -e "$INSTALL_TO" ]]
	then

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
	fi

	FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}_${LATEST_BUILD}.zip"

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL=$(curl -sfLS "$XML_FEED" | awk -F'"' '/releaseNotes/{print $4}' | ${HEAD_OR_TAIL} -1)

		( curl -H "Accept-Encoding: gzip,deflate" -sfLS "$RELEASE_NOTES_URL" \
			| gunzip \
			| sed '1,/<details open id="primary">/d; /<details>/,$d' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

			# save the HTML too
		curl -sfLS "$RELEASE_NOTES_URL" > "$FILENAME:r.html"

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

		echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

		mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

		EXIT="$?"

		if [[ "$EXIT" != "0" ]]
		then

			echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

			exit 1
		fi
	fi

	echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

		# Move the file out of the folder
	mv -n "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

	EXIT="$?"

	if [[ "$EXIT" = "0" ]]
	then

		echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	else
		echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

		exit 1
	fi

fi # Use version 3 or 4, else 5

exit 0
#
#EOF
