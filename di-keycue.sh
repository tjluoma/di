#!/usr/bin/env zsh -f
# Purpose: Download and install/update late version of KeyCue
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-09-07

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/KeyCue.app'

RELEASE_NOTES_URL='https://www.ergonis.com/products/keycue/history.html'

HOMEPAGE='https://www.ergonis.com/products/keycue/'

	# The server doesn't like `curl` so we pretend not to be `curl`
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Safari/605.1.15'

if [[ -e "$HOME/.config/di/prefers/KeyCute-Beta.txt" ]]
then
		#  Source: https://www.ergonis.com/downloads/beta/
	FEED="https://update.ergonis.com/downloads/beta/keycue/keycuev.xml?s=0"
	BETA='yes'
	NAME="$NAME (beta)"
	PREFIX="beta-"
	URL=$(curl -sfLS "https://www.ergonis.com/downloads/beta/" | egrep -i 'keycue.*\.dmg' | sed 's#.*href="#https://www.ergonis.com/downloads/beta/#g ; s#.dmg.*#.dmg#g')

else
		## Source: https://www.ergonis.com/downloads/dnld_keycue.html
		## https://www.ergonis.com/downloads/keycue-install.dmg redirects to actual DMG
	URL=$(curl -A "$UA" --head -sfL "https://www.ergonis.com/downloads/keycue-install.dmg" | awk -F' |\r' '/^Location:/{print $2}' || echo https://www.ergonis.com/downloads/keycue-install.dmg)
	FEED="https://update.ergonis.com/vck/keycue.xml?s=0"
	PREFIX=''
	BETA='no'
fi

LATEST_VERSION=$(curl -A "$UA" -sfLS "$FEED" \
				| egrep "<Program_Version>.*</Program_Version>" \
				| sed 's#.*<Program_Version>##g ; s#</Program_Version>##g' \
				| tr -d '\r')

[[ "$LATEST_VERSION" == "" ]] && echo "$NAME: 'LATEST_VERSION' is empty." && exit 1


URL_CODE=$(curl -A "$UA" --head --silent $URL | awk -F' ' '/^HTTP/{print $2}')

if [[ "$URL_CODE" != "200" ]]
then
	echo "$NAME: HTTP code for '$URL' is '$URL_CODE' (should be '200')"
	exit 1
fi

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${PREFIX}${LATEST_VERSION}.dmg"

if (( $+commands[lynx] ))
then

	if [[ "$BETA" = "no" ]]
	then

		(curl -A "$UA" -sfLS "$RELEASE_NOTES_URL" \
		| awk '/<h1>/{i++}i==1' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist \
		| sed 's#^ *##g' ;\
		echo "\nURL: ${URL}\n") | tee "$FILENAME:r.txt"

	else

		if (( $+commands[unrtf] ))
		then

			RTF=$(curl -sfLS "https://www.ergonis.com/downloads/beta/" | tr '"' '\012' | egrep -i '^KeyCue.*\.rtf' | sed 's#^#https://www.ergonis.com/downloads/beta/#g')

			( curl -sfLS "$RTF" \
			| command unrtf \
			| lynx -dump -nomargins -width='10000' -assume_charset='UTF-8' -pseudo_inlines -stdin \
			| sed G ; \
			  echo "\nURL for RTF: $RTF\n" ) \
			| tee "$FILENAME:r.txt"

		fi # unrtf

	fi # beta

fi # lynx

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl -A "$UA" --continue-at - --fail --location --output "$FILENAME" "$URL"

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

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to Trash. ('mv' \$EXIT = $EXIT)"

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
