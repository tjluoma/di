#!/bin/zsh -f
# Purpose: Download and install iStat Menus 5 or 6 from <https://bjango.com/mac/istatmenus/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-20

NAME="$0:t:r"

INSTALL_TO="/Applications/iStat Menus.app"

HOMEPAGE="https://bjango.com/mac/istatmenus/"

DOWNLOAD_PAGE="http://download.bjango.com/istatmenus/"

SUMMARY="An advanced Mac system monitor for your menu bar."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# @TODO - integrate new testing code at bottom of script

	# Default to iStat Menus 6 unless we're told to use v5
USE_VERSION='6'

URL=$(curl --silent --location --fail --head http://download.bjango.com/istatmenus6/ \
		| awk -F' |\r' '/Location.*\.zip/{print $2}' \
		| tail -1)

function use_istat_v5 {

	USE_VERSION='5'

	URL=$(curl --silent --location --fail --head http://download.bjango.com/istatmenus5/ \
		| awk -F' |\r' '/Location.*\.zip/{print $2}' \
		| tail -1)

	ASTERISK='(Note that version 6 is now available.)'
}

if [[ -e "$INSTALL_TO" ]]
then
		# if v5 is installed, check that. Otherwise, use v6
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "5" ]]
	then
		use_istat_v5
	fi
else
	if [ "$1" = "--use5" -o "$1" = "-5" ]
	then
		use_istat_v5
	fi
fi

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
		echo "	See <https://itunes.apple.com/us/app/istat-menus/id1319778037?mt=12> or"
		echo "	<macappstore://itunes.apple.com/us/app/istat-menus/id1319778037>"
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

		RELEASE_NOTES_URL='https://bjango.com/mac/istatmenus/versionhistory/'

		( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r Version " ;
			(curl -sfL "$RELEASE_NOTES_URL" \
			| sed '1,/<div class="button-moreinfo">/d; /<\/p>/,$d' ; echo '</p>') \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

	fi
fi

echo "$NAME: Downloading \"$URL\" to \"$FILENAME\":"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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








if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)
	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

else
	INSTALLED_VERSION='6.10'
	INSTALLED_BUILD='964'
fi

CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString)
DARWIN_VERSION=$(uname -r)
OS_VER=$(sw_vers -productVersion)
MAC_MODEL=$(sysctl hw.model | awk -F' ' '/^hw.model/{print $NF}')

INFO=($(curl --silent --location --fail "https://updates.bjango.com/istatmenus6/version-json.php" \
	-X POST \
	-H "Accept: */*" \
	-H "User-Agent: iStat%20Menus/1025 CFNetwork/${CFNETWORK_VER} Darwin/${DARWIN_VERSION} (x86_64)" \
	-H "Accept-Language: en-us" \
	--data-urlencode "version=${INSTALLED_VERSION}" \
	--data-urlencode "build=${INSTALLED_BUILD}" \
	--data-urlencode "platform=${OS_VER}" \
	--data-urlencode "model=${MAC_MODEL}" \
	--data-urlencode "language=en-US" \
	--data-urlencode "ui=1" \
	| tr ',' '\012' \
	| egrep '"(build|version)":' \
	| tr -dc '[0-9]\.\n'))

LATEST_BUILD="$INFO[1]"
LATEST_VERSION="$INFO[2]"

URL=$(curl --silent --location --fail --head 'https://download.bjango.com/istatmenus6/' \
		| awk -F' |\r' '/Location.*\.zip/{print $2}' \
		| tail -1)

echo "
URL: $URL
LATEST_VERSION: $LATEST_VERSION
LATEST_BUILD: $LATEST_BUILD
"











#EOF
