#!/bin/zsh -f
# Purpose: Download and install/update the latest version of "Do Not Disturb"
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-13

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

HOMEPAGE="https://objective-see.com/products/dnd.html"

DOWNLOAD_PAGE="https://objective-see.com/products/dnd.html"

RELEASE_NOTES_URL='https://objective-see.com/products/changelogs/DoNotDisturb.txt'

SUMMARY="Physical access (or “evil maid”) attacks are some of the most insidious threats faced by those of us who travel with our Macs. Do Not Disturb (DND) is a free, open-source utility that aims to detect and alert you of such attacks."

INSTALL_TO='/Applications/Do Not Disturb.app'

INFO=($(curl -H "Accept-Encoding: gzip,deflate" -sfLS 'https://objective-see.com/products/dnd.html' \
		| gunzip --force \
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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.zip"

SHA_FILE="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.sha1.txt"

echo "$EXPECTED_SHA1 ?$FILENAME:t" >| "$SHA_FILE"

( curl -H "Accept-Encoding: gzip,deflate" -sfLS "$RELEASE_NOTES_URL" \
	| gunzip -f -c) | tee "$FILENAME:r.txt"

OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -lt "12" ]
then
	echo "$NAME: [WARNING] '$INSTALL_TO:t' is only compatible with macOS versions 10.12 and higher (you are using 10.$OS_VER)."
	echo "$NAME: [WARNING] Will download, but the app might not install or function properly."
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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

MAC_TYPE=$(sysctl hw.model | awk -F' ' '/^hw.model/{print $NF}' | tr -d '[0-9],')

case "$MAC_TYPE" in
	MacBook|MacBook*)
			:
	;;

	iMac|iMac*)
		echo "$NAME: '$INSTALL_TO:t' can only be installed on MacBook, but this is an ${MAC_TYPE}. Installation cancelled."

		exit 0
	;;

	*)
		echo "$NAME: '$INSTALL_TO:t' can only be installed on MacBook, but this is a ${MAC_TYPE}. Installation cancelled."

		exit 0
	;;

esac



##

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

INSTALLER="$UNZIP_TO/Do Not Disturb Installer.app"

echo "$NAME: launching custom installer/updater: '$INSTALLER'"

	# launch the custom installer app and wait for it to finish.
open -a "$INSTALLER"

exit 0
#
#EOF
