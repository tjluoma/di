#!/usr/bin/env zsh -f
# Purpose: The Missing Bluetooth Manager
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-04-24

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Juice.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/Juice.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://deadbeef.me/Juice/appcast.xml'

	## 2019-10-21 - there is only 1 item in the feed, and now it is a zip not a dmg
INFO=($(curl -sSfL "${XML_FEED}" \
		| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version|url=' \
		| head -2 \
		| sort ))

RELEASE_NOTES_URL='https://deadbeef.me/Juice/releasenotes.html'

LATEST_VERSION=$(echo "$INFO[1]" | sed 's#sparkle:version="##g; s#"##g')

URL=$(echo "$INFO[2]" | sed 's#url="##g; s#"##g')

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$RELEASE_NOTES_URL" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	RELEASE_NOTES_URL: $RELEASE_NOTES_URL
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

if (( $+commands[lynx] ))
then

	(curl -sfLS $RELEASE_NOTES_URL \
		| awk '/<h2>/{i++}i==1' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nonumbers -nolist -stdin ;
	echo "\nFeed:	$XML_FEED\nSource:	$RELEASE_NOTES_URL\nURL:	$URL\n") | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TRASH/"

	mv -fv "$FILENAME:r".* "$TRASH/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TRASH}/${NAME}-XXXXXXXX")

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$TRASH/'."

	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$TRASH'."

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"


exit 0
#EOF
