#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-10-06

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO="/Library/PreferencePanes/BackblazeBackup.prefPane"

# mac_version="5.4.0.246" mac_url="%DEST_HOST%/api/install_backblaze?file=bzinstall-mac-5.4.0.246.zip"

INFO=($(curl -sfLS 'https://secure.backblaze.com/api/clientversion.xml' | awk -F'"' '/mac_version/{print $2" "$4}'))

LATEST_VERSION="$INFO[1]"

URL=$(echo "$INFO[2]" | sed 's#%DEST_HOST%#https://secure.backblaze.com#g')

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

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
	ACTION_WORD='upgrade'

else

	FIRST_INSTALL='yes'
	ACTION_WORD='installation'
fi

FILENAME="$HOME/Downloads/Backblaze-${LATEST_VERSION}.zip"

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
	echo "$NAME: Unzip successful to '$UNZIP_TO':"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

TARGET="$UNZIP_TO/bzdoinstall.app"

if [[ ! -d "$TARGET" ]]
then
	echo "$NAME: Nothing found at '$TARGET'!"
	exit 1
fi

	# The app will install / update an existing installation, so all we need to do it launch it

echo "$NAME: Launching '$TARGET'. User action required to finish $ACTION_WORD of Backblaze."

open "$TARGET"

exit 0
#EOF
