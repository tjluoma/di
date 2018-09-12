#!/bin/zsh -f
# Purpose: Download and install the latest version of Keybase
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-30

NAME="$0:t:r"

HOMEPAGE="https://keybase.io"

DOWNLOAD_PAGE="https://prerelease.keybase.io/Keybase.dmg"

SUMMARY="The Keybase app:
*	has built-in encrypted chat, for teams and DM's
*	has built-in encrypted filesharing
*	has built-in encrypted, signed git hosting
*	gives you crypto commands in your command-line
*	is open source
It's also free, of course."

INSTALL_TO="/Applications/Keybase.app"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

UPDATE_FEED='https://prerelease.keybase.io/update-darwin-prod-v2.json'

# CFBundleShortVersionString and CFBundleVersion are identical

INFO=($(curl -sfLS "$UPDATE_FEED" \
		| egrep '"(version|url)":' \
		| sed 's#^ *"##g; s#,##g; s#"##g' \
		| sort \
		| awk '{print $2}'))

URL="$INFO[1]"
LATEST_VERSION="$INFO[2]"

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

(echo "$NAME: Release Notes (from json feed) for $INSTALL_TO:t:r ($LATEST_VERSION):" ;
curl -sfLS "$UPDATE_FEED" \
| egrep '"description": ' \
| sed 's#.*"description": "##g ; s#",##g' \
| sed 's#\\n#\
#g') | tee -a "$FILENAME:r.txt"

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
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -qf "$INSTALL_TO/Contents/SharedSupport/bin/"

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then
		LAUNCH='yes'

		for i in "$HOME/Library/LaunchAgents"/keybase.*.plist
		do
			launchctl unload "$i" && echo "$NAME: unloaded '$i' from launchd."
		done

	fi

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

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

[[ "$LAUNCH" = "yes" ]] && open --hide -a "$INSTALL_TO"

exit 0
#EOF
