#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of VPN Unlimited
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-08-03; updated 2019-10-24
# Verified:	2025-02-22
#
#
# 2018-08-09 - 	RELEASE_NOTES_URL ☹️ cannot find a change log or release notes page anywhere.
#
# 2025-02-22 - 	The Mac App Store version is at 9.1 even though the "direct" version is at 8.7
# 				https://apps.apple.com/us/app/vpn-unlimited-for-mac/id727593140?mt=12

NAME="$0:t:r"

INSTALL_TO='/Applications/VPN Unlimited.app'

HOMEPAGE="https://www.vpnunlimitedapp.com/"

DOWNLOAD_PAGE="https://www.vpnunlimitedapp.com/en/downloads/mac"

SUMMARY="VPN Unlimited allows you to protect your privacy and get unlimited access to your favorite Web sites worldwide."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

URL="https://www.vpnunlimited.com/api/keepsolid/vpn-download?platform=mac"

REMOTE_FILENAME=$(curl -sS --head --location "$URL" | awk -F' |\r' '/^.ocation:/{print $2}')

LATEST_VERSION=$(echo "$REMOTE_FILENAME:t:r" | tr -dc '[0-9]\.')

	# If either of these are blank, we cannot continue
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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/vpn-unlimited-wifi-proxy/id727593140?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/vpn-unlimited-wifi-proxy/id727593140>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/VPNUnlimited-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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

echo -n "$NAME: Unmounting $MNTPNT: "&& diskutil eject "$MNTPNT"

exit 0
#EOF
