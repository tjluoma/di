#!/bin/zsh -f
# Purpose: Download and install the latest version of OnyX
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-13

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO="/Applications/OnyX.app"

HOMEPAGE="https://www.titanium-software.fr/en/onyx.html"

DOWNLOAD_PAGE="https://www.titanium-software.fr/en/onyx.html"

SUMMARY="OnyX is a multifunction utility that you can use to verify the structure of the system files, to run miscellaneous maintenance and cleaning tasks, to configure parameters in the Finder, Dock, Safari, and some of Apple's applications, to delete caches, to remove certain problematic folders and files, to rebuild various databases and indexes, and more."

OS_VER=$(sw_vers -productVersion | cut -d. -f2)

	# this should work back to 10.4
URL="https://www.titanium-software.fr/download/10${OS_VER}/OnyX.dmg"

IFS=$'\n' INFO=($(curl -sfLS 'https://www.titanium-software.fr/en/onyx.html' \
				| fgrep -i -B1 -A1 "https://www.titanium-software.fr/download/10${OS_VER}/OnyX.dmg" ))

LATEST_VERSION=$(echo "$INFO[1]" | sed -e 's#.*<h1>OnyX ##g' -e 's# for .*##g')

EXPECTED_SHA256=$(echo "$INFO[3]" | sed -e 's#.* ##g' -e 's#<.*##g')

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" -o "$EXPECTED_SHA256" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	EXPECTED_SHA256: $EXPECTED_SHA256
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

FILENAME="$HOME/Downloads/OnyX-${LATEST_VERSION}-for-OS-10.${OS_VER}.dmg"

SHA_FILE="$HOME/Downloads/OnyX-${LATEST_VERSION}-for-OS-10.${OS_VER}.sha256.txt"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

##

echo "$EXPECTED_SHA256 ?$FILENAME:t" > "$SHA_FILE"

cd "$FILENAME:h"

echo -n "$NAME: Verifying sha256 of '$FILENAME': "

shasum -c "$SHA_FILE"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Verification successful"

else
	echo "$NAME: Verification failed (\$EXIT = $EXIT)"

	exit 1
fi


##

echo "$NAME: Accepting the EULA and mounting '$FILENAME' (sorry if this opens a Finder window):"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
