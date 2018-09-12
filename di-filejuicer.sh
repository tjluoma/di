#!/bin/zsh -f
# Purpose: Download and install File Juicer
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-20

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/File Juicer.app'

HOMEPAGE="https://echoone.com/filejuicer/"

DOWNLOAD_PAGE="https://echoone.com/filejuicer/download"

SUMMARY="File Juicer doesn’t care what type file you drop onto it; it searches the entire file byte by byte. If it finds a JPEG, JP2, PNG, GIF, PDF, BMP, WMF, EMF, PICT, TIFF, Flash, Zip, HTML, WAV, MP3, AVI, MOV, MPG, WMV, MP4, AU, AIFF or text file inside, it can save it to your desktop or to another folder you choose."

URL=$(curl -sfLS --head 'https://echoone.com/filejuicer/latestversion?f=unknown' \
		| awk -F' |\r' '/^.ocation/{print $2}' \
		| tail -1)

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/FileJuicer-$LATEST_VERSION.zip"

echo "$NAME: Downloading \"$URL\" to \"$FILENAME\":"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping $FILENAME to $UNZIP_TO:"

ditto --noqtn -xk "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto --noqtn -xkv \"$FILENAME\" \"$UNZIP_TO\")"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$HOME/.Trash/\"."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of \"$INSTALL_TO:t\" (from \"$UNZIP_TO\") to \"$INSTALL_TO\"."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed \"$UNZIP_TO/$INSTALL_TO:t\" to \"$INSTALL_TO\"."

else
	echo "$NAME: Failed to move \"$UNZIP_TO/$INSTALL_TO:t\" to \"$INSTALL_TO\"."

	exit 1
fi

exit 0
#EOF
