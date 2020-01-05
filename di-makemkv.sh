#!/usr/bin/env zsh -f
# Purpose: Download and install latest version of MakeMKV.app
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-21

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/MakeMKV.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/MakeMKV.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

HOMEPAGE="http://www.makemkv.com/"

DOWNLOAD_PAGE="http://www.makemkv.com/download/"

SUMMARY="MakeMKV is your one-click solution to convert video that you own into free and patents-unencumbered format that can be played everywhere. MakeMKV is a format converter, otherwise called “transcoder”."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

###############################################################################################
	## I can't seem to find an RSS feed for the updates, although it does have some sort
	## of update checking
	## So, instead, I make an ugly-hack-ish check for an URL with 'dmg' in it

if (( $+commands[lynx] ))
then

		# if lynx is installed, use it,
		# since it is better at parsing HTML than a shell script ever will be
	URL=$(lynx -dump -nonumbers -listonly 'http://www.makemkv.com/download/' \
			| egrep '^http.*\.dmg' \
			| head -1)

else
		# if lynx is not installed, parse the output of 'curl'

	URL=$(curl -sfL 'http://www.makemkv.com/download/' \
			| fgrep .dmg \
			| sed 's#.dmg.*#.dmg#g ; s#.*/download/#http://www.makemkv.com/download/#g' \
			| head -1)
fi

if [[ "$URL" == "" ]]
then
	echo "$NAME: Error: URL is empty"
	exit 1
fi

LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

	# If any of these are blank, we should not continue
if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: LATEST_VERSION is empty"
	exit 1
fi

###############################################################################################

if [ -e "$INSTALL_TO" ]
then
	INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null | tr -d 'v'`

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

fi

###############################################################################################

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

###############################################################################################

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL='http://www.makemkv.com/download/'

	SECOND_VERSION=$(curl -sfL "${RELEASE_NOTES_URL}" \
					| egrep '<li>MakeMKV v.* \(.* \)</li>' \
					| sed -n '2p' \
					| sed 's#</li>##g')

	( echo -n "$NAME: Release Notes for" ;
	curl -sfL 'http://www.makemkv.com/download/' \
	| sed "1,/<h4>Revision history<\/h4>/d ; /$SECOND_VERSION/,\$d" \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| sed 's#^ ##g' ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

###############################################################################################

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

########################################################################################################################

echo "$NAME: Mounting $FILENAME:"

	# This will accept the DMG's EULA without reading it, just like you would have!
MNTPNT=`echo -n "Y" \
	| hdid -plist "$FILENAME" 2>/dev/null \
	| fgrep '/Volumes/' \
	| sed 's#</string>##g ; s#.*<string>##g'`

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$TRASH'. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi

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

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
