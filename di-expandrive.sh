#!/usr/bin/env zsh -f
# Purpose: 	Download and Install the latest version of ExpanDrive for Mac from <http://www.expandrive.com>
#
# From:		Tj Luo.ma
# Mail:		luomat at gmail dot com
# Web: 		http://RhymesWithDiploma.com
# Date:		2015-07-30
# Verified:	2025-02-24

NAME="$0:t:r"

INSTALL_TO='/Applications/ExpanDrive.app'

	# Do Not Use: http://updates.expandrive.com/apps/expandrive.xml

XML_FEED='https://updates.expandrive.com/appcast/expandrive7.json?version=7.0.0'

HOMEPAGE="https://www.expandrive.com"

DOWNLOAD_PAGE="https://www.expandrive.com/download-expandrive/"

SUMMARY="Access files in the cloud from Finder or Explorer without having to sync or use disk space. ExpanDrive mounts OneDrive, Google Drive, Dropbox, Box, Sharepoint, Amazon S3, FTP, SFTP and more as a Network Drive."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

URL=$(curl -sfLS "$XML_FEED" | awk -F'"' '/url/{print $4}')

LATEST_VERSION=$(echo "$URL" | awk -F'/' '/http/{print $7}' | tr '-' '.')

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nLATEST_VERSION: $LATEST_VERSION\nURL: $URL"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output  "$FILENAME" "$URL"

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
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$HOME/.Trash/\"."

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

[[ "$FIRST_INSTALL" == "yes" ]] && echo "$NAME: Launching $INSTALL_TO:t:r" && open -a "$INSTALL_TO"

exit 0
#
#EOF
