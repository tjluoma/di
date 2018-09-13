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

SUMMARY="Physical access (or “evil maid”) attacks are some of the most insidious threats faced by those of us who travel with our Macs. Do Not Disturb (DND) is a free, open-source utility that aims to detect and alert you of such attacks."

INSTALL_TO='/Applications/Do Not Disturb.app'

DARWIN=$(uname -r)

CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString)

APP_NAME_FOR_UA=$(echo "$INSTALL_TO:t:r" | sed 's# #%20#g')

INFO=($(curl -sfLS "https://objective-see.com/products.json" \
  -H "Accept: */*" \
  -H "Accept-Language: en-us" \
  -H "User-Agent: ${APP_NAME_FOR_UA}/1.2.2 CFNetwork/${CFNETWORK_VER} Darwin/${DARWIN} (x86_64)" \
  | sed -e '1,/"Do Not Disturb":/d; /}/,$d' -e 's#,##g' -e 's#"##g' \
  | egrep '(version|zip)' \
  | sort \
  | awk '{print $NF}'))

	# the app uses the same version number for both CFBundleShortVersionString and CFBundleVersion
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# 2018-09-13 - Temporary workaround for incorrect version/URL info in 'products.json'
if [ "$LATEST_VERSION" = "1.2.1" -o "$URL" = "https://bitbucket.org/objective-see/deploy/downloads/DND_1.2.1.zip" ]
then

	URL=$(curl -sfLS 'https://objective-see.com/products/dnd.html' | gunzip | tr -s '"|\047' '\012' | egrep '^http.*\.zip' | head -1)
	LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

fi

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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r:l}// /}-${LATEST_VERSION}.zip"

RELEASE_NOTES_URL='https://objective-see.com/products/changelogs/DoNotDisturb.txt'

( curl -sfLS "$RELEASE_NOTES_URL" \
	| gunzip \
	| awk '/^VERSION/{i++}i==1' ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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

echo "$NAME: launching custom installer/updater: '$UNZIP_TO/Do Not Disturb Installer.app'"

	# launch the custom installer app and wait for it to finish.
open -W -a "$UNZIP_TO/Do Not Disturb Installer.app"

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
#
#EOF
