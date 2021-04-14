#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest Dropshare
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-10-11

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

### XML_FEED='https://getdropsha.re/sparkle/Dropshare5.xml'
## 2018-12-15 - SSL certificate not valid for 'getdropsha.re'

XML_FEED='https://dropshare.app/sparkle/Dropshare5.xml'

HOMEPAGE="https://dropshare.app"

DOWNLOAD_PAGE="https://dropshare.app/download"

SUMMARY="Upload Screen Shots, Screen Recordings, files, literally anything to you favorite hosting provider and share it immediately with anyone."

INSTALL_TO='/Applications/Dropshare 5.app'

INFO=($(curl -sfLS $XML_FEED \
		| egrep '<sparkle:releaseNotesLink>|<enclosure url' \
		| head -2 \
		| tr '>|<| ' '\012' \
		| egrep '^(http.*\.html|url=|sparkle:version)' \
		| sort \
		| tr '"' ' ' \
		| awk '{print $NF}'))

RELEASE_NOTES_URL="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# This is sort of a hack-y way of getting the latest version info, but it's not listed in the XML_FEED directly
LATEST_VERSION=$(echo "$RELEASE_NOTES_URL:t:r" | tr -dc '[0-9]\.')

# echo "
# RELEASE_NOTES_URL: $RELEASE_NOTES_URL
# LATEST_BUILD: $LATEST_BUILD
# LATEST_VERSION: $LATEST_VERSION
# URL: $URL
# "

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

FILENAME="$HOME/Downloads/Dropshare-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	( lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "${RELEASE_NOTES_URL}" ; \
	  echo "\nSource: <$RELEASE_NOTES_URL>" ) \
	| tee "$FILENAME:r.txt"

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
