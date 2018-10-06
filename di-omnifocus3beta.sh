#!/bin/zsh -f
# Purpose: Keep OmniFocus 3 beta up-to-date
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

autoload msg

GROWL_APP='OmniFocus'

INSTALL_TO="/Applications/OmniFocus.app"

INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion 2>/dev/null || echo '120.1.0.319233')

DARWIN_VERSION=$(uname -r)

CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString)

ARCH=$(uname -m)

FEED_URL="https://update.omnigroup.com/appcast/com.omnigroup.OmniFocus3/$INSTALLED_VERSION/private-test"

TEMPFILE="${TMPDIR-/tmp}${NAME}.$$.$RANDOM.xml"

curl -sfLS "$FEED_URL" \
  -H "Accept: */*" \
  -H "Accept-Language: en-us" \
  -H "User-Agent: com.omnigroup.OmniSoftwareUpdate.OSUCheckService/1 CFNetwork/${CFNETWORK_VER} Darwin/${DARWIN_VERSION} ($ARCH)" \
| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 > "$TEMPFILE"

[[ ! -s "$TEMPFILE" ]] && msg "$TEMPFILE is zero bytes." && exit 0

LATEST_VERSION=$(fgrep '<omniappcast:buildVersion>' "$TEMPFILE" 2>/dev/null | tail -1 | sed 's#<omniappcast:buildVersion>##g ; s#</omniappcast:buildVersion>##g' )

[[ "$LATEST_VERSION" == "" ]] && echo "$NAME: '\$LATEST_VERSION' is empty." && exit 1

if [[ -e "$INSTALL_TO" ]]
then

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date (Installed: $INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
	LAUNCH='yes'
fi

INFO=($(egrep '^<enclosure ' "$TEMPFILE" | tail -1 | tr '"' ' '))

BYTES="$INFO[5]"

URL="$INFO[7]"

EXPECTED_SHA256="$INFO[9]"

# echo "
# BYTES: $BYTES
# URL: $URL
# SHA256: $SHA256
# "

	# We don't need to save this for later, so we'll download it to a temp dir
FILENAME="/tmp/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.tbz2"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

msg "Updating OmniFocus to latest version ($LATEST_VERSION)"

zmodload zsh/stat

while [ "`zstat -L +size ${FILENAME} 2>/dev/null`" -lt "$BYTES" ]
do

	curl --continue-at - --fail --location --output "$FILENAME" "$URL"

done

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && msg --sticky "Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && msg --sticky "$FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && msg --sticky "$FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

ACTUAL_SHA256=$(shasum -a 256 "$FILENAME" | awk '{print $1}')

if [[ "$EXPECTED_SHA256" == "$ACTUAL_SHA256" ]]
then
	echo "$NAME: Verified sha256 checksum of '$FILENAME'"
else
	msg --sticky "sha256 checksum FAILED for '$FILENAME'"
	exit 0
fi

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: untar/bunzip-ing '$FILENAME' to '$UNZIP_TO':"

tar -x -C "$UNZIP_TO" -j -f "$FILENAME"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Untar successful"
else
		# failed
	msg  --sticky "Failed (tar exit = $EXIT)"

	exit 0
fi

if [[ -e "$INSTALL_TO" ]]
then

		# if OmniFocus is running, then tell it to quit
		# (It will sync itself if necessary, because it's smart)

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "OmniFocus" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		msg --sticky "Failed to move existing $INSTALL_TO to $HOME/.Trash/"

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
	msg --sticky "Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 0
fi

if [[ "$LAUNCH" = "yes" ]]
then

	echo "$NAME: launching '$INSTALL_TO':"

		# doesn't seem to re-launch unless we add a little 'sleep'
	sleep 5

	open -g -j -a "$INSTALL_TO"

fi

msg "Updated to $LATEST_VERSION"

exit 0
#EOF
