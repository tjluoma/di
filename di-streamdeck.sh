#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of Stream Deck
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-08-15

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Stream Deck.app'

MIN_REQUIRED='10.12'

FEED="https://gc-updates.elgato.com/mac/sd-update/final/app-version-check.json"

TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.json"

curl -sfLS "$FEED" >| "$TEMPFILE"

if (( $+commands[jq] ))
then
		# if we have `jq` installed, this is so much easier
	INFO="$TEMPFILE"

	# the json file has an 'automatic' and 'manual' section. Right now they are identical,
	# but I can imagine (read: guess) that they might use "Manual" for a slow-rollout of
	# a newer version. I'm going to use whichever is newer _IFF_ 'jq' is installed
	# Otherwise we'll just use 'Automatic'

	LATEST_VERSION_AUTOMATIC=$(jq --raw-output .Automatic.Version < "$TEMPFILE")

	LATEST_VERSION_MANUAL=$(jq --raw-output .Manual.Version < "$TEMPFILE")

	if [[ "$LATEST_VERSION_AUTOMATIC" == "$LATEST_VERSION_MANUAL" ]]
	then

		LATEST_VERSION="$LATEST_VERSION_AUTOMATIC"
		URL=$(jq --raw-output .Automatic.fileURL < "$TEMPFILE")
		RELEASE_NOTES_URL=$(jq --raw-output .Automatic.ReleaseNotes.en < "$TEMPFILE")

	else

		autoload is-at-least

		is-at-least "$LATEST_VERSION_AUTOMATIC" "$LATEST_VERSION_MANUAL"

		EXIT="$?"

		if [[ "$EXIT" == "0" ]]
		then

			echo "$NAME: Versions differ:\n\tAutomatic: $LATEST_VERSION_AUTOMATIC\n\t   Manual: $LATEST_VERSION_MANUAL\n\tUsing 'Automatic'."

			LATEST_VERSION="$LATEST_VERSION_AUTOMATIC"
			URL=$(jq --raw-output .Automatic.fileURL < "$TEMPFILE")
			RELEASE_NOTES_URL=$(jq --raw-output .Automatic.ReleaseNotes.en < "$TEMPFILE")

		else

			echo "$NAME: Versions differ:\n\tAutomatic: $LATEST_VERSION_AUTOMATIC\n\t   Manual: $LATEST_VERSION_MANUAL\n\tUsing 'Manual'."

			LATEST_VERSION="$LATEST_VERSION_MANUAL"
			URL=$(jq --raw-output .Manual.fileURL < "$TEMPFILE")
			RELEASE_NOTES_URL=$(jq --raw-output .Manual.ReleaseNotes.en < "$TEMPFILE")
		fi
	fi



else
		# no jq? Fine, we'll do it the hard/inefficient/error-prone way

	INFO=$(sed 's#,"Manual":.*##' "$TEMPFILE")
	LATEST_VERSION=$(echo "$INFO" | sed 's#.*"Version":"##g ; s#",".*##g')
	URL=$(echo "$INFO" | sed 's#.*"fileURL":"##g ; s#".*##g')
	RELEASE_NOTES_URL=$(echo "$INFO" | sed 's#.*"ReleaseNotes":{"en":"##g ; s#\.html.*#.html#g')

fi

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	RELEASE_NOTES_URL: $RELEASE_NOTES_URL
	"

	exit 1
fi


if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION_FIRST=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_VERSION_LAST=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	INSTALLED_VERSION="$INSTALLED_VERSION_FIRST.$INSTALLED_VERSION_LAST"

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.pkg"

if (( $+commands[lynx] ))
then

	(lynx -dump -nomargins -width='100' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ;\
	echo "\nURL: $URL") | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

OS_VER=$(sw_vers -productVersion)

autoload is-at-least

is-at-least "$MIN_REQUIRED" "$OS_VER"

EXIT="$?"

if [[ "$EXIT" = "1" ]]
then

	echo "$NAME: '$INSTALL_TO:t' requires '$MIN_REQUIRED' but this Mac is running '$OS_VER'. The file has been downloaded, but will not be installed:\n${FILENAME}\n"

	exit 0

fi

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME"

else

	(sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en | tee -a "$FILENAME:r.install.log") || open -R "$FILENAME"

fi

exit 0
#EOF

# https://www.elgato.com/en/gaming/downloads
#
# https://gc-updates.elgato.com/mac/sd-update/final/download-website.php ->
# https://edge.elgato.com/egc/macos/sd/Stream_Deck_4.3.2.11299.pkg
#
# https://gc-updates.elgato.com/mac/sd-update/final/app-version-check.json
