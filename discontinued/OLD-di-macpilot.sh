#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of MacPilot
# See https://www.koingosw.com/products/macpilot/
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-27

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/MacPilot.app"

NAME="$0:t:r"

HOMEPAGE="https://www.koingosw.com/products/macpilot/"

DOWNLOAD_PAGE="https://www.koingosw.com/products/macpilot/#download"

SUMMARY="Scared of the terminal or can’t be bothered to remember those commands to customize your system the way you want? MacPilot is your digital savior. Easily enable and disable hidden features in Mac OS X."

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion)

function use_v8 {

	# MacPilot-8.0.8 requires 10.11
	# MacPilot 8.1 requires 10.9 ? (or Mac OS 10.10 according to website )
	# That seems weird

	ASTERISK='(Note that version 11 is also available.)'
	INFO='(Valued are hard-coded)'
	# URL="http://www.koingosw.com/products/getmirrorfile.php?path=%2Fproducts%2Fmacpilot%2Fdownload%2Fold%2Fmacpilot_81_intel_1010.dmg"
	URL='http://mirror.koingosw.com/products/macpilot/download/old/macpilot_81_intel_1010.dmg'
	LATEST_VERSION="8.1"
}

function use_v9 {

	ASTERISK='(Note that version 11 is also available.)'
	# URL="http://www.koingosw.com/products/getmirrorfile.php?path=%2Fproducts%2Fmacpilot%2Fdownload%2Fold%2Fmacpilot_914_intel_1012.dmg"
	URL='http://mirror.koingosw.com/products/macpilot/download/old/macpilot_914_intel_1012.dmg'
	LATEST_VERSION="9.1.4"
}

function use_v10 {

		# Requires Mac OS X 10.12
		# and will work with 10.13 and 10.14
		# but so will MacPilot ver 11
	ASTERISK='(Note that version 11 is also available.)'

	URL='http://mirror.koingosw.com/products/macpilot/download/old/macpilot_1015_intel_for_1014.dmg'

	LATEST_VERSION='10.15.0'

}

function use_v11 {

		# This version requires at least Mac OS X 10.13.

	XML_FEED='https://www.koingosw.com/postback/versioncheck.php?appname=macpilot&type=sparkle'

	LATEST_VERSION=$(curl --insecure -sfLS "$XML_FEED"| tr ' ' '\012' | egrep '^sparkle:version=' | head -1 | tr -dc '[0-9]\.')

	# URL='http://mirror.koingosw.com/products/macpilot/download/macpilot.dmg'

	URL='https://www.koingosw.com/products/getmirrorfile.php?path=%2Fproducts%2Fmacpilot%2Fdownload%2Fmacpilot.dmg'

}


case "$OS_VER" in
	10.13|10.14|10.15)
		use_v11
	;;

	10.12)
		use_v10
		# Could also use v9 with 10.12
	;;

	10.10|10.11)
		use_v8
	;;

esac

if [[ -e "$INSTALL_TO" ]]
then
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

		# if v8 or v9 or v10 are installed, check that. Otherwise, use v11
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "8" ]]
	then
		use_v8
	elif [[ "$MAJOR_VERSION" == "9" ]]
	then
		use_v9
	elif [[ "$MAJOR_VERSION" == "10" ]]
	then
		use_v10
	else
		use_v11
	fi
else
	if [ "$1" = "--use8" -o "$1" = "-8" ]
	then
		use_v8
	elif [ "$1" = "--use9" -o "$1" = "-9" ]
	then
		use_v9
	elif [ "$1" = "--use10" -o "$1" = "-10" ]
	then
		use_v10
	else
		use_v11
	fi
fi

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	XML_FEED: $XML_FEED
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
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
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"

RELEASE_NOTES="$FILENAME:r.txt"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

		# Have to call lynx twice because the release notes are encoded as HTML characters.
		# The result of the first 'lynx' is regular HTML.
		# Weird.

	(curl --insecure -sfLS "$XML_FEED" \
		| awk '/<description>/{i++}i==2' \
		| tr -d '\012| ' \
		| sed 's#<description>##g ; s#</description>.*##g' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| sed G ; \
	echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>\n\nURL: ${URL}" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --insecure --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$RELEASE_NOTES" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$RELEASE_NOTES" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$RELEASE_NOTES"
fi

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}.app.$RANDOM"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
#
#EOF
