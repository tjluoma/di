#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-10

NAME="$0:t:r"

INSTALL_TO="/Applications/VMware Fusion.app"

# XML_FEED='https://softwareupdate.vmware.com/cds/vmw-desktop/fusion.xml'

# /Applications/VMware Fusion.app:
# 	CFBundleShortVersionString: 10.1.3
# 	CFBundleVersion: 9472307

HOMEPAGE="https://www.vmware.com/products/fusion.html"

DOWNLOAD_PAGE="https://www.vmware.com/go/getfusion"

# locurl.sh
# https://download3.vmware.com/software/fusion/file/VMware-Fusion-10.1.3-9472307.dmg

URL=$(curl -sfLS --head https://www.vmware.com/go/getfusion | awk -F' |\r' '/^.ocation:/{print $2}')

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#VMware-Fusion-##g ; s#-.*##g')

LATEST_BUILD=$(echo "$URL:t:r" | sed 's#VMware-Fusion-.*-##g')

SUMMARY="Fusion brings Mac virtualization to the next level with a simply powerful and powerfully simple desktop virtualization utility."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# If any of these are blank, we cannot continue
if [ "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
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

FILENAME="$HOME/Downloads/VMWareFusion-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Accepting EULA and mounting $FILENAME:"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep -A 1 '<key>mount-point</key>' | tail -1 | sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

open "$MNTPNT/VMware Fusion.app"

exit 0
#EOF
