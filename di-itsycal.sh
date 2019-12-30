#!/bin/zsh -f
# Purpose: Download and install the latest version of Itsycal
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-20

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/itsycal.app'
else
	INSTALL_TO='/Applications/itsycal.app'
fi

XML_FEED='https://s3.amazonaws.com/itsycal/itsycal.xml'

HOMEPAGE="https://www.mowglii.com/itsycal/"

DOWNLOAD_PAGE="https://s3.amazonaws.com/itsycal/Itsycal.zip"

SUMMARY="Itsycal is a tiny menu bar calendar. If you want, it will display your events as a companion to the Mac Calendar app. You can also create and delete (but not edit) events."

RELEASE_NOTES_URL='https://s3.amazonaws.com/itsycal/changelog.html'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -ge "12" ]
then

	INFO=($(curl -sSfL "${XML_FEED}" \
			| tr -s ' ' '\012' \
			| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
			| head -3 \
			| sort \
			| awk -F'"' '/^/{print $2}'))

		# "Sparkle" will always come before "url" because of "sort"
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

elif [ "$OS_VER" -lt "12" ]
then

	# I'm not sure how far back 0.10.16 supports.
	# Check https://www.mowglii.com/itsycal/versionhistory.html
	# for more details
	echo "$NAME [info]: Using Itsycal version 0.10.16 for Mac OS X 10.$OS_VER."
	URL='https://s3.amazonaws.com/itsycal/Itsycal-0.10.16.zip'
	LATEST_VERSION="0.10.16"
	LATEST_BUILD="0.10.16"
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	( curl -sfLS "$RELEASE_NOTES_URL" \
	| awk '/<a id=/{i++}i==1' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

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
#EOF
