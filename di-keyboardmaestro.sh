#!/bin/zsh -f
# Purpose: Download and install the latest version of Keyboard Maestro from <http://www.keyboardmaestro.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Keyboard Maestro.app'

HOMEPAGE="https://www.keyboardmaestro.com/"

DOWNLOAD_PAGE="https://www.keyboardmaestro.com/action/download?km"

SUMMARY="Whether you are a power user or a just getting started, your time is precious. So why waste it when Keyboard Maestro can help improve almost every aspect of using your Mac. Even the simplest things, like typing your email address, or going to Gmail or Facebook, launching Pages, or duplicating a line, all take time and add frustration. Let Keyboard Maestro help make your Mac life more pleasant and efficient."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# Keyboard%20Maestro%20Engine/8.2.4 CFNetwork/974.1 Darwin/18.0.0 (x86_64)

ENGINE_VERSION=$(defaults read "${INSTALL_TO}/Contents/MacOS/Keyboard Maestro Engine.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo 8.2.4)

CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString 2>/dev/null)

DARWIN_VER=$(uname -r)

UA="Keyboard%20Maestro%20Engine/$ENGINE_VERSION CFNetwork/$CFNETWORK_VER Darwin/$DARWIN_VER (x86_64)"

LAUNCH_APP="no"

LAUNCH_ENGINE="yes"

	# This is not your normal XML_FEED, by a long-shot.
FEED='https://www.keyboardmaestro.com/action/sivc?M&U&08248000&6ABF5EF7&xxxxxxxx&00000000&000010E0&KM&EN'

TEMPFILE="${TMPDIR-/tmp}${NAME}.$$.$RANDOM.txt"

curl -H "Accept: */*" -H "Accept-Language: en-us" -A "$UA" -sfLS "$FEED" > "$TEMPFILE"

URL=$(awk -F' ' '/ReleaseURL:/{print $2}' "$TEMPFILE")

LATEST_VERSION=$(awk -F' ' '/^\]Changes in /{print $3}' "$TEMPFILE" | head -1)

MD5_SUM_EXPECTED=$(awk -F' ' '/ReleaseMD5:/{print $2}' "$TEMPFILE")

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi


# If we get here, we _are_ outdated. Now we just need to figure out which URL to use.

FILENAME="$HOME/Downloads/KeyboardMaestro-${LATEST_VERSION}.zip"

(echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):" ; \
 awk '/\]Changes in/{i++}i==1' "$TEMPFILE" | sed 's#^\]##g') \
| tee "$FILENAME:r.txt"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl -H "Accept: */*" -H "Accept-Language: en-us" -A "$UA" --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

MD5_SUM_ACTUAL=$(md5 -q "$FILENAME")

if [[ "$MD5_SUM_ACTUAL" == "$MD5_SUM_EXPECTED" ]]
then
	echo "$NAME: '$FILENAME' passed checksum validation"
else
	echo "$NAME: '$FILENAME' failed checksum validation (Expected '$MD5_SUM_EXPECTED' vs Actual: '$MD5_SUM_ACTUAL'.)"
	exit 1
fi

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

	pgrep -q 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& osascript -e 'tell application "Keyboard Maestro Engine" to quit'

	pgrep -q 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& pkill -f 'Keyboard Maestro Engine'

	pgrep -q 'Keyboard Maestro' \
	&& LAUNCH_APP='yes' \
	&& osascript -e 'tell application "Keyboard Maestro" to quit'

	pgrep -q 'Keyboard Maestro' \
	&& LAUNCH_ENGINE='yes' \
	&& pkill -f 'Keyboard Maestro'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Keyboard Maestro.$INSTALLED_VERSION.$RANDOM.app"

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

if [ "$FIRST_INSTALL" = "yes" -o "$LAUNCH_APP" ]
then
	echo "$NAME: Launching '$INSTALL_TO':"
	open -a "$INSTALL_TO"
fi

[[ "$LAUNCH_ENGINE" == "yes" ]] && echo "$NAME: Launching 'Keyboard Maestro Engine.app':" && open -a "${INSTALL_TO}/Contents/MacOS/Keyboard Maestro Engine.app"

exit 0
#EOF
