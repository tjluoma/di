#!/usr/bin/env zsh -f
# Purpose: Install Bartender 2 or 3 depending on OS version or what's installed already
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

NAME="$0:t:r"

HOMEPAGE="https://www.macbartender.com"

DOWNLOAD_PAGE="https://www.macbartender.com/Demo/Bartender%203.zip"

SUMMARY="Bartender 3 lets you organize your menu bar icons, by hiding them, rearranging them, show hidden items with a click or keyboard shortcut and have icons show when they update."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INSTALL_V1_TO="/Applications/Bartender.app"
INSTALL_V2_TO="/Applications/Bartender 2.app"
INSTALL_V3_TO='/Applications/Bartender 3.app'
INSTALL_V4_TO='/Applications/Bartender 4.app'

OS_VER=$(sw_vers -productVersion | cut -d '.' -f 1,2)

function use_v1 {

	INSTALL_TO="/Applications/Bartender.app"

	URL='http://www.macbartender.com/updates/latest/Bartender.zip'

	LATEST_VERSION="1.3.3"

	LATEST_BUILD="96"

}


function use_v2 {

	if [[ "$CAN_USE_2" = "yes" ]]
	then
		XML_FEED='https://www.macbartender.com/B2/updates/updates.php'

		IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
						| fgrep 'https://macbartender.com/B2/updates/2' \
						| egrep 'sparkle:version|sparkle:shortVersionString=|url=' \
						| tail -1 \
						| sort ))

		URL=$(echo "$INFO" | sed 's#.*https://#https://#g; s#.zip".*#.zip#g;')

		LATEST_VERSION=$(echo "$INFO" | sed 's#.*sparkle:shortVersionString="##g; s#".*##g; ')

		LATEST_BUILD=$(echo "$INFO" | sed 's#.*sparkle:version="##g; s#".*##g;')

		INSTALL_TO="/Applications/Bartender 2.app"

		ASTERISK='(Note that version 3 is also available.)'
		USE_VERSION='2'
	else
		echo "$NAME: Cannot use v2 with 10.$OS_VER. See <https://www.macbartender.com/faq/> for more information."
		exit 0
	fi
}

function use_v3 {

	if [ "$CAN_USE_3" = "yes" ]
	then

		USE_VERSION='3'

		INSTALL_TO='/Applications/Bartender 3.app'

				# if you want to install beta releases
				# create a file (empty, if you like) using this file name/path:
		PREFERS_BETAS_FILE="$HOME/.config/di/bartender3-prefer-betas.txt"

		if [[ -e "$PREFERS_BETAS_FILE" ]]
		then

			if [[ "$NAME" == "$0:t:r" ]]
			then
				NAME="$NAME (beta releases)"
			fi

				# Reports itself as 'http://macbartender.com/B2/updates/TestAppcast.xml'
			XML_FEED='https://www.macbartender.com/B2/updates/TestUpdates.php'

		else
				# This is for non-beta
				# Feed reports itself as 'http://macbartender.com/B2/updates/Appcast.xml'
				# which is weird because it's for Bartender 3, not 2. But OK.
			XML_FEED='https://www.macbartender.com/B2/updates/updatesB3.php'
		fi

		INFO=($(curl -sSfL "${XML_FEED}" \
				| tr -s ' ' '\012' \
				| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
				| tail -3 \
				| sort \
				| awk -F'"' '/^/{print $2}'))

			# "Sparkle" will always come before "url" because of "sort"
		LATEST_VERSION="$INFO[1]"
		LATEST_BUILD="$INFO[2]"
		URL="$INFO[3]"
	else
		echo "$NAME: Cannot use v3 with 10.$OS_VER. See <https://www.macbartender.com/faq/> for more information."
		exit 0
	fi
}


function use_v4 {

	if [ "$CAN_USE_4" = "yes" ]
	then

		USE_VERSION='4'

		INSTALL_TO='/Applications/Bartender 4.app'

				# if you want to install beta releases
				# create a file (empty, if you like) using this file name/path:
		PREFERS_BETAS_FILE="$HOME/.config/di/bartender4-prefer-betas.txt"

		if [[ -e "$PREFERS_BETAS_FILE" ]]
		then

			if [[ "$NAME" == "$0:t:r" ]]
			then
				NAME="$NAME (beta releases)"
			fi

				# Reports itself as 'http://macbartender.com/B2/updates/TestAppcast.xml'
			XML_FEED='https://www.macbartender.com/B2/updates/TestUpdatesB4.php'

		else
				# This is for non-beta
				# Feed reports itself as 'http://macbartender.com/B2/updates/Appcast.xml'
				# which is weird because it's for Bartender 3, not 2. But OK.
			XML_FEED='https://www.macbartender.com/B2/updates/updatesB4.php'
		fi

		INFO=($(curl -sSfL "${XML_FEED}" \
				| tr -s ' ' '\012' \
				| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
				| tail -3 \
				| sort \
				| awk -F'"' '/^/{print $2}'))

			# "Sparkle" will always come before "url" because of "sort"
		LATEST_VERSION="$INFO[1]"
		LATEST_BUILD="$INFO[2]"
		URL="$INFO[3]"
	else
		echo "$NAME: Version 4 requires macOS 11. See <https://www.macbartender.com/faq/> for more information."
		exit 0
	fi
}



case "$OS_VER" in
	11.*)
		CAN_USE_3='no'
		CAN_USE_2='no'
		CAN_USE_4='yes'
		use_v4
	;;

	10.13|10.14|10.15)
		CAN_USE_4='no'
		CAN_USE_3='yes'
		CAN_USE_2='no'
		use_v3
	;;

	10.12)
		CAN_USE_4='no'
		CAN_USE_3='yes'
		CAN_USE_2='yes'
	;;

	10.10|10.11)
		CAN_USE_4='no'
		CAN_USE_3='no'
		CAN_USE_2='yes'
		use_v2
	;;

	10.9|10.8|10.7|10.6)
		CAN_USE_4='no'
		CAN_USE_3='no'
		CAN_USE_2='no'
		use_v1
	;;

	*)
		echo "$NAME: There is no version of Bartender for $OS_VER." >>/dev/stderr
		exit 2
	;;

esac

 if [[ -e "$INSTALL_V4_TO" ]]
then
	use_v4
elif [[ -e "$INSTALL_V3_TO" ]]
then
	use_v3
elif [[ -e "$INSTALL_V2_TO" ]]
then
	use_v2
elif [[ -e "$INSTALL_V1_TO" ]]
then
	use_v1
else
	use_v3
fi

	# If any of these are blank, we should not continue
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

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" | awk -F'>|<' '/sparkle:releaseNotesLink/{print $3}' | tail -1)

FILENAME="$HOME/Downloads/Bartender-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if [[ "$USE_VERSION" == "4" ]]
then


	if (( $+commands[pandoc] ))
	then
			# pandoc is better than lynx or html2text
			# but it also unnecessarily escapes ' and some other
			# characters. Hence the 'tr'
		( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n" ;
		curl -sfLS "$RELEASE_NOTES_URL" \
		| pandoc --from html --to markdown --wrap=none \
		tr -d '\\';
		echo "\nSource: ${RELEASE_NOTES_URL}" ) | tee "$FILENAME:r.txt"

	elif (( $+commands[html2text] ))
	then
		# lynx can parse the HTML just fine, but its output is sort of ugly,
		# so we'll use html2text if it's available

		( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n" ;
		curl -sfL "${RELEASE_NOTES_URL}" | html2text -nobs ;
		echo "\nSource: ${RELEASE_NOTES_URL}" ) | tee "$FILENAME:r.txt"

	elif (( $+commands[lynx] ))
	then

		( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n" ;
		lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ;
		echo "\nSource: ${RELEASE_NOTES_URL}" ) | tee "$FILENAME:r.txt"

	fi
fi

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

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

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
#
#EOF
