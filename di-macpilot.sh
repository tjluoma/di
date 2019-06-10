#!/bin/zsh -f
# Purpose: Download and install the latest version of MacPilot
# {Note/@todo: ideally this script would use `sw_vers` to make sure to download the right version for the particular OS the user is running.}
# See https://www.koingosw.com/products/macpilot/
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-27

NAME="$0:t:r"

INSTALL_TO='/Applications/MacPilot.app'

HOMEPAGE="https://www.koingosw.com/products/macpilot/"

DOWNLOAD_PAGE="https://www.koingosw.com/products/macpilot/#download"

SUMMARY="Scared of the terminal or can’t be bothered to remember those commands to customize your system the way you want? MacPilot is your digital savior. Easily enable and disable hidden features in Mac OS X."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

OS_VER=$(sw_vers -productVersion)

function use_v8 {

	ASTERISK='(Note that version 10 is also available.)'
	INFO='(Valued are hard-coded)'
	URL="http://www.koingosw.com/products/getmirrorfile.php?path=%2Fproducts%2Fmacpilot%2Fdownload%2Fold%2Fmacpilot_81_intel_1010.dmg"
	LATEST_VERSION="8.1"
}

function use_v9 {

	ASTERISK='(Note that version 10 is also available.)'
	URL="http://www.koingosw.com/products/getmirrorfile.php?path=%2Fproducts%2Fmacpilot%2Fdownload%2Fold%2Fmacpilot_914_intel_1012.dmg"
	LATEST_VERSION="9.1.4"
}

function use_v10 {

	if [[ -e "$INSTALL_TO" ]]
	then
		INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`
	else
		# we need to fake that we've installed something if it isn't installed, so I chose '10'
		# since it's the most recent major version as of this writing
		INSTALLED_VERSION='10'
	fi

XML_FEED="http://www.koingosw.com/postback/versioncheck.php?appname=macpilot&appversion=${INSTALLED_VERSION}&sysplatform=Mac%20OS%20X&sysversion=Mac%20OS%20X%20${OS_VER}"

	INFO=($(curl --silent --location --fail "$XML_FEED" \
			| fgrep -A3 '<macpilot>' \
			| egrep '(<version>|<macpath>)' \
			| sort \
			| sed 's#.*<version>##g ; s#</version>##g; s#.*<macpath>##g; s#</macpath>##g; '
		))

	# URL="$INFO[1]"

	URL='http://mirror.koingosw.com/products/macpilot/download/macpilot.dmg'

		# That's the only version info the app uses
	# LATEST_VERSION="$INFO[2]"

	LATEST_VERSION=$(curl --silent --location --fail "$XML_FEED" \
						| fgrep -B1 'macpilot.dmg' \
						| awk -F'>|<' '/version/{print $3}')
}

case "$OS_VER" in
	10.12|10.13|10.14)
		use_v10
	;;

	10.10|10.11)
		use_v8
	;;

esac

if [[ -e "$INSTALL_TO" ]]
then
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

		# if v8 or v9 are installed, check that. Otherwise, use v10
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "8" ]]
	then
		use_v8
	elif [[ "$MAJOR_VERSION" == "9" ]]
	then
		use_v9
	else
		use_v10
	fi
else
	if [ "$1" = "--use9" -o "$1" = "-9" ]
	then
		use_v9
	else
		use_v10
	fi
fi

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

		# have to call lynx twice because the release notes are encoded as HTML characters. Weird.

	( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
	curl -sfL "$RELEASE_NOTES_URL" | sed '1,/<macpilot>/d ; /<\/macpilot>/,$d' \
	| egrep -vi "<version|minimumSystemVersion|macpath>" \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
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
