#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of TaskExplorer
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-20

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/TaskExplorer.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/TaskExplorer.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

HOMEPAGE="https://objective-see.com/products/taskexplorer.html"

DOWNLOAD_PAGE="https://objective-see.com/products/taskexplorer.html"

SUMMARY=" Explore all the tasks (processes) running on your Mac with TaskExplorer. Quickly see a task’s signature status, loaded dylibs, open files, network connection, and much more"

RELEASE_NOTES_URL='https://objective-see.com/products/changelogs/TaskExplorer.txt'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INFO=($(curl -H "Accept-Encoding: gzip,deflate" -sfLS "$HOMEPAGE" \
		| gunzip -f -c \
		| tr -s '"|\047' '\012' \
		| egrep '^http.*\.zip|sha-1:' \
		| awk '{print $NF}' \
		| head -2))

URL="$INFO[1]"

EXPECTED_SHA1="$INFO[2]"

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" -o "$EXPECTED_SHA1" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	EXPECTED_SHA1: $EXPECTED_SHA1
	"

	exit 1
fi

if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: Cannot determine LATEST_VERSION for $INSTALL_TO."
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# CFBundleVersion is identical
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

OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -lt "8" ]
then
	echo "$NAME: [WARNING] '$INSTALL_TO:t' is only compatible with macOS versions 10.8 and higher (you are using 10.$OS_VER)."
	echo "$NAME: [WARNING] Will download, but the app might not install or function properly."
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.zip"

SHA_FILE="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.sha1.txt"

echo "$EXPECTED_SHA1 ?$FILENAME:t" >| "$SHA_FILE"

## RELEASE_NOTES_URL - begin

( curl -H "Accept-Encoding: gzip,deflate" -sfLS "$RELEASE_NOTES_URL" \
	| gunzip -f -c ) | tee "$FILENAME:r.txt"

## RELEASE_NOTES_URL - end

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

##

echo "$NAME: Checking '$FILENAME' against '$SHA_FILE':"

cd "$FILENAME:h"

shasum -c "$SHA_FILE"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: SHA-1 verification passed"

else
	echo "$NAME: SHA-1 verification failed (\$EXIT = $EXIT)"

	exit 1
fi

##

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TRASH/"

	mv -fv "$FILENAME:r".* "$TRASH/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TRASH}/${NAME}-XXXXXXXX")

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$TRASH/'."

	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$TRASH'."

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
