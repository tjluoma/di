#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of ChronoSync
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-12-20

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/ChronoSync.app'
else
	INSTALL_TO='/Applications/ChronoSync.app'
fi

URL='https://downloads.econtechnologies.com/updates/CS4_Download.dmg'

FEED='https://www.econtechnologies.com/UC/updatecheck.php?prod=ChronoSync&vers=4.0&lang=en&plat=mac&os=10.14.1&hw=i64&req=1'

INFO=$(curl -sfLS "$FEED" |\
sed 's#<br>#\
#g')

LATEST_VERSION=$(echo "$INFO" | awk -F'=' '/^VERSION/{print $NF}')

RELEASE_NOTES_URL=$(echo "$INFO" | awk -F'=' '/^NOTICE/{print $NF}')

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

if (( $+commands[lynx] ))
then

	lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" | tee "$FILENAME:r.txt"

	echo "\nVersion: ${LATEST_VERSION}\nSource: ${RELEASE_NOTES_URL}\nURL: $URL" | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

PKG=$(find "$MNTPNT" -maxdepth 1 -iname 'Install.pkg' -print)

if [[ "$PKG" == "" ]]
then
	echo "$NAME: No 'Install.pkg' found in '$MNTPNT'." >>/dev/stderr
	exit 1
fi

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$PKG"
else
	sudo /usr/sbin/installer -verbose -pkg "$PKG" -dumplog -target / -lang en 2>&1
fi

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then

	echo "$NAME: installation of '$PKG' failed (\$EXIT = $EXIT)."

		# Show the .pkg file at least, to draw their attention to it.
	open -R "$PKG"

	exit 1
fi

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
#EOF
