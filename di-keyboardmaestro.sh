#!/bin/zsh -f
# Purpose: Download and install the latest version of Keyboard Maestro from <http://www.keyboardmaestro.com> (including betas, if enabled)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-07-12

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

BETAS_ENABLED=$(defaults read com.stairways.keyboardmaestro.engine CheckForBetas 2>/dev/null)

if [ "$BETAS_ENABLED" = "1" -o "$BETAS_ENABLED" = "yes" ]
then
	URL_STRING='TestURL'
	MD5_STRING='TestMD5'
	RELEASE_NOTES_PREFIX='>'
else
	URL_STRING='ReleaseURL'
	MD5_STRING='ReleaseMD5'
	RELEASE_NOTES_PREFIX=']'
fi

INSTALL_TO='/Applications/Keyboard Maestro.app'

ENGINE_VERSION=$(defaults read "${INSTALL_TO}/Contents/MacOS/Keyboard Maestro Engine.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo 8.2.4)

CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString 2>/dev/null)

DARWIN_VER=$(uname -r)

UA="Keyboard%20Maestro%20Engine/$ENGINE_VERSION CFNetwork/$CFNETWORK_VER Darwin/$DARWIN_VER (x86_64)"

TEMPFILE="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM.txt"

rm -f "$TEMPFILE"

	# get the URL but clean up some weird characters (encoding issue?)
curl -A "$UA" -sfLS "https://www.keyboardmaestro.com/action/sivc?M&U&08248000&6ABF5EF7&xxxxxxxx&00000000&000010E0&KM&EN" \
	| sed -e "s#Ò#“#g" -e "s#ÉÓ#”#g" -e "s#Ó#”#g" -e 's#Õ#’#g' >| "$TEMPFILE"

URL=$(awk -F' ' "/^$URL_STRING:/{print \$2}" "$TEMPFILE")

EXPECTED_MD5=$(awk -F' ' "/^$MD5_STRING:/{print \$2}" "$TEMPFILE")

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#keyboardmaestro-##g')

	# If any of these are blank, we cannot continue
if [ "$EXPECTED_MD5" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	EXPECTED_MD5: $EXPECTED_MD5
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

		# note that we are removing '.' from the version info, which is unusual but necessary given LATEST_VERSION formatting
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | tr -d '.')

	if [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]
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

( 	egrep "^${RELEASE_NOTES_PREFIX}" "$TEMPFILE" | sed "s#^${RELEASE_NOTES_PREFIX}##g" ;
	echo "\n\n LATEST_VERSION: $LATEST_VERSION\n EXPECTED_MD5: $EXPECTED_MD5 \nURL: $URL \n" ) \
| tee "$FILENAME:r.txt"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl -A "$UA" --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

## Verify download vs expected

ACTUAL_MD5=$(md5 -q "$FILENAME")

if [[ "$ACTUAL_MD5" == "$EXPECTED_MD5" ]]
then
	echo "\n$NAME: MD5 signature verified\n" | tee -a "$FILENAME:r.txt"
else
	echo "\n$NAME: MD5 signature MISMATCH: Expected $EXPECTED_MD5 but actual is $ACTUAL_MD5. Will not install.\n" | tee -a "$FILENAME:r.txt"
	exit 1
fi

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

	pgrep -qx 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& osascript -e 'tell application "Keyboard Maestro Engine" to quit'

	pgrep -qx 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& pkill -f 'Keyboard Maestro Engine'

	while [ "`pgrep -x 'Keyboard Maestro'`" != "" ]
	do

		MSG="$NAME: Keyboard Maestro (app not just the engine) is running. Cannot update. Waiting 30 seconds."

		echo  "$MSG"

		growlnotify  \
		--appIcon "Keyboard Maestro" \
		--identifier "$NAME" \
		--message "$MSG" \
		--title "$NAME"

	done

	osascript -e 'tell application "Keyboard Maestro" to quit'

	pgrep -qx 'Keyboard Maestro' && pkill -x 'Keyboard Maestro'

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


## Renaming the file like this prevents the script from recognizing that it has already downloaded the proper file(s)



	# get nicer-formatted version information from install
ACTUAL_INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

	# this is what the download _should_ have been named
BETTER_FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${ACTUAL_INSTALLED_VERSION}.zip"

	# rename the download
mv -vn "$FILENAME" "$BETTER_FILENAME"

	# rename the Release Notes
mv -vn "$FILENAME:r.txt" "$BETTER_FILENAME:r.txt"

exit 0
#EOF
