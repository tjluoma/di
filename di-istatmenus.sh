#!/usr/bin/env zsh -f
# Purpose: 	Download and install iStat Menus 7 from <https://bjango.com/mac/istatmenus/>
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-07-20
# Verified:	2025-02-24

NAME="$0:t:r"

INSTALL_TO="/Applications/iStat Menus.app"

HOMEPAGE="https://bjango.com/mac/istatmenus/"

DOWNLOAD_PAGE="http://download.bjango.com/istatmenus/"

SUMMARY="An advanced Mac system monitor for your menu bar."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# https://download.bjango.com/istatmenus/updater/ also redirects the latest version

URL=$(curl --silent --location --fail --head http://download.bjango.com/istatmenus7/ \
		| awk -F' |\r' '/Location.*\.zip/{print $2}' \
		| tail -1)

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/istat-menus-7/id6499559693?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/istat-menus-7/id6499559693>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/iStatMenus-${LATEST_VERSION}.zip"

if [ "$USE_VERSION" = "6" ]
then
	if (( $+commands[lynx] ))
	then

		# "https://updates.bjango.com/istatmenus6/releasenotes.php"
		RELEASE_NOTES_URL='https://bjango.com/mac/istatmenus/versionhistory/'

		( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r Version " ;
			(curl -sfL "$RELEASE_NOTES_URL" \
			| sed '1,/<div class="button-moreinfo">/d; /<\/p>/,$d' ; echo '</p>') \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

	fi
fi

echo "$NAME: Downloading \"$URL\" to \"$FILENAME\":"

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
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$HOME/.Trash/\"."

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

exit 0
#
#EOF
