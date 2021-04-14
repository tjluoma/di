#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Marked 2
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-03-30; 2020-02-27 dmg -> zip

NAME="$0:t:r"

INSTALL_TO='/Applications/Marked 2.app'

HOMEPAGE="http://marked2app.com"

DOWNLOAD_PAGE="http://marked2app.com/download/Marked.dmg"

SUMMARY="Marked is a previewer for Markdown files. Use it with your favorite text editor and it updates every time you save. With robust features for previewing, reviewing and exporting beautiful documents, you can work in plain text while reveling in rich formatting."

XML_FEED="https://updates.marked2app.com/marked.xml"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INFO=$(curl -sfLS "$XML_FEED" \
		| awk '/<item>/{i++}i==1' \
        | sed 's#^[      ]*##g' \
        | tr -s '\012|\r| ' ' ' \
        | sed -e 's#> <#><#g' -e 's#> #>#g' -e 's# <#<#g')

URL=$(echo "$INFO" | sed -e 's#.* url="##g' -e 's#" .*##g')

RELEASE_NOTES_URL=$(echo "$INFO" | sed -e 's#.*<sparkle:releaseNotesLink>##g' -e 's#</sparkle:releaseNotesLink>.*##')

LATEST_VERSION=$(echo "$INFO" | sed -e 's#.* sparkle:shortVersionString="##g' -e 's#" .*##g')

LATEST_BUILD=$(echo "$INFO" | sed -e 's#.* sparkle:version="##g' -e 's#" .*##g')

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/marked-2/id890031187?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/marked-2/id890031187>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/Marked-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	(echo -n "$NAME: Release Notes for " ;
	lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "${RELEASE_NOTES_URL}" \
	| fgrep -v 'Follow @markedapp on Twitter' \
	| tr -s '_' '_' \
	| uniq ;
	echo "\nSource: <${RELEASE_NOTES_URL}>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME'"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv  "$FILENAME" "$HOME/.Trash/"

	mv -fv  "$FILENAME:r".* "$HOME/.Trash/"

	exit 1

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${HOME}/.Trash/${NAME}-XXXXXXXX")

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$HOME/.Trash'."

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -n "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
