#!/bin/zsh -f
# Purpose: Download and install/update the latest version of Printopia v3
#
# From: Timothy J. Luoma
# Mail: luomat at gmail dot com
# Date: 2018-08-26

NAME="$0:t:r"

INSTALL_TO="/Applications/Printopia.app"

XML_FEED="https://www.decisivetactics.com/api/checkupdate?app_id=com.decisivetactics.printopia"

HOMEPAGE="https://www.decisivetactics.com/products/printopia/"

DOWNLOAD_PAGE="https://www.decisivetactics.com/products/printopia/"

SUMMARY="Wireless printing to any printer. Share any printer, old or new, with your iPad or iPhone."

zmodload zsh/stat #needed for zstat

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function check_bytes { ACTUAL_BYTES=$(zstat -L +size "$FILENAME" 2>/dev/null || echo '0') }

IFS=$'\n' INFO=($(curl -sfLS "$XML_FEED" \
					| egrep '"app_version"|"app_version_short"|"sha2"|"size"|"url"' \
					| head -5 \
					| sed 's#^[	 ]*##g' \
					| tr -d '"|,' \
					| sort \
					| awk -F' ' '/:/{print $2}' ))

LATEST_BUILD="$INFO[1]"
LATEST_VERSION="$INFO[2]"
EXPECTED_SHASUM256="$INFO[3]"
EXPECTED_BYTES="$INFO[4]"
URL="$INFO[5]"

## Useful for debugging, if needed
# echo "
# LATEST_BUILD: ${LATEST_BUILD}
# LATEST_VERSION: ${LATEST_VERSION}
# EXPECTED_SHASUM256: ${EXPECTED_SHASUM256}
# EXPECTED_BYTES: ${EXPECTED_BYTES}
# URL: ${URL}
# "

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

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.zip"

SHA256_FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.sha256"

echo "$EXPECTED_SHASUM256  $FILENAME:t" > "$SHA256_FILENAME"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="https://www.decisivetactics.com/products/printopia/release-notes-sparkle"

	(echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
		curl -sfLS "${RELEASE_NOTES_URL}" \
		| awk '/<h2>/{i++}i==1' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| sed '/./,/^$/!d' ; \
		echo "\nSource: <$RELEASE_NOTES_URL>") | tee -a "$FILENAME:r.txt"
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

check_bytes

COUNT='0'

while [ "$EXPECTED_BYTES" -gt "$ACTUAL_BYTES" ]
do

	((COUNT++))

	## Useful for debugging, if needed
	# echo "
	# ACTUAL_BYTES: 		$ACTUAL_BYTES
	# EXPECTED_BYTES: 	$EXPECTED_BYTES
	# "

	curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

	check_bytes

		# if this loop runs 10 times, give up.
	[[ "$COUNT" -gt "10" ]] && break

done

if [[ "`zstat -L +size "$FILENAME" 2>/dev/null`" == "$EXPECTED_BYTES" ]]
then
		echo "$NAME: '$FILENAME' is the correct size."
else
		echo "$NAME: '$FILENAME' is the wrong size. Cannot continue."
		exit 1
fi

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Verifying shasum of $FILENAME:"

ACTUAL_SHASUM256=$(shasum -a 256 "$FILENAME" | awk '{print $1}')

shasum -a 256 --check "$SHA256_FILENAME"

SHA_EXIT="$?"

if [ "$SHA_EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' passed shasum verification."

else

	echo "$NAME: '$FILENAME' failed shasum verification: \n\tExpected: $EXPECTED_SHASUM256\n\tReceived: $ACTUAL_SHASUM256"
	echo "$NAME: Installation/Upgrade cancelled"

		# if the file has failed validation, we probably shouldn't leave it sitting in their
		# ~/Downloads/ directory. So let's give it an obvious "THIS IS BAD DO NOT TOUCH"
		# name and move it to the Trash. We could delete it, but I'm loathe to delete anything o
		# another person's computer, so putting it in the trash seems like a good compromise.
	mv -vf "$FILENAME" "$TRASH/$FILENAME:t:r.Corrupted-BAD-CHECKSUM-Do-Not-Use.$ACTUAL_SHASUM256.zip"

		# clean up the checksum file as well.
	mv -vf "$FILENAME" "$TRASH/$SHA256_FILENAME"

	exit 1
fi

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk "$FILENAME" "$UNZIP_TO"

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
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
# EOF
