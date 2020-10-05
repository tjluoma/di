#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of "What's Your Sign?"
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

HOMEPAGE="https://objective-see.com/products/whatsyoursign.html"

DOWNLOAD_PAGE="https://objective-see.com/products/whatsyoursign.html"

RELEASE_NOTES_URL='https://objective-see.com/products/changelogs/WhatsYourSign.txt'

SUMMARY="Verifying a file's cryptographic signature can deduce its origin or trustability. Unfortunately on macs there's no simple way to view a file's signature via the UI. WhatsYourSign adds a menu item to Finder.app. Simply right-, or control-click on any file to display its cryptographic signing information!"

INSTALL_TO='/Applications/WhatsYourSign.app'

INFO=($(curl -H "Accept-Encoding: gzip,deflate" -sfLS "$HOMEPAGE" \
		| gunzip -f -c \
		| tr -s '"|\047' '\012' \
		| egrep '^http.*\.zip|sha-1:' \
		| awk '{print $NF}' \
		| head -2))

URL="$INFO[1]"

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
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

( curl -H "Accept-Encoding: gzip,deflate" -sfLS "$RELEASE_NOTES_URL" \
	| gunzip -f -c) | tee "$FILENAME:r.txt"

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f2)

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

# echo "$NAME: Checking '$FILENAME' against '$SHA_FILE':"
#
# cd "$FILENAME:h"
#
# shasum -c "$SHA_FILE"
#
# EXIT="$?"
#
# if [ "$EXIT" = "0" ]
# then
# 	echo "$NAME: SHA-1 verification passed"
#
# else
# 	echo "$NAME: SHA-1 verification failed (\$EXIT = $EXIT)"
#
# 	exit 1
# fi

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

INSTALLER="$UNZIP_TO/WhatsYourSign Installer.app"

echo "$NAME: launching custom installer/updater: '$INSTALLER'"

	# launch the custom installer app
open -a "$INSTALLER"

exit 0
#
#EOF
