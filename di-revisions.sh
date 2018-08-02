#!/bin/zsh -f
# Purpose: Download and install latest version of Revisions
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

INSTALL_TO='/Applications/Revisions.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# NOTE: "https://revisionsapp.com/releases" is not an XML_FEED

if [ -e "$INSTALL_TO" ]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	XML_FEED="http://www.revisionsapp.com/checkforupdate/web/$INSTALLED_VERSION"

	##########################################################################################
	## This feed gives a very small amount of information, such as this:
	##
	# 	{
	# 	  "updateAvailable": 0,
	# 	  "noUpdateAvailable": 1,
	# 	  "latestVersion": "3.0.1"
	# 	}
	##########################################################################################

	LATEST_VERSION=`curl -sfL "$XML_FEED" | awk -F'"' '/latestVersion/{print $4}'`

		# If any of these are blank, we should not continue
	if [ "$LATEST_VERSION" = "" ]
	then
		echo "$NAME: Error: bad data received:\nLATEST_VERSION: $LATEST_VERSION"
		exit 0
	fi

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

		# NOTE! We are GUESSING here, because the feed does not actually contain the
		# download URL. This relies on the developer not changing the website

		# Look to see if there is a DMG listed in the HTML of the page
	SHORT_URL=`curl -sfL https://www.revisionsapp.com | fgrep -i '.dmg' | awk -F"'" '//{print $2}'`

	if [[ "$SHORT_URL" == "" ]]
	then
			# If we did NOT find anything, try to guess that the developer used the same naming
			# convention as currently in use when this script was written
		URL="https://www.revisionsapp.com/downloads/revisions-$LATEST_VERSION.dmg"
	else
			# If we DID find something, use it
			## NOTE! This assumes that the SHORT_URL is a relative one
		URL="https://www.revisionsapp.com${SHORT_URL}"
	fi

	HTTP_STATUS=`curl --head -sfL "$URL" | awk -F' ' '/HTTP/{print $2}'`

	if [[ "$HTTP_STATUS" != "200" ]]
	then

		echo "$NAME: $INSTALL_TO is out of date ($INSTALLED_VERSION vs $LATEST_VERSION) but URL is not correct $URL" \
		| tee -a "$HOME/Desktop/$NAME.error.log"

		exit 0
	else
		echo "$NAME: Out of Date: $INSTALLED_VERSION vs $LATEST_VERSION"
	fi

	FILENAME="$HOME/Downloads/Revisions-${LATEST_VERSION}.dmg"

else

		# If we get here then Revisions is not installed

	URL=$(curl -sfL https://www.revisionsapp.com | fgrep '.dmg' | sed "s#.*downloads/#https://www.revisionsapp.com/downloads/#g ; s#'\;##g ; s# ##g")

	FILENAME="$HOME/Downloads/$URL:t"

fi
# IF installed


echo "$NAME: Downloading >$URL< to >$FILENAME<"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

	# This will agree to the EULA for you without you reading it
	# If you do not want that, don't use this script
MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [ -e "$INSTALL_TO" ]
then
		## 		Quit app, if running
		# 	pgrep -xq "Revisions" \
		# 	&& LAUNCH='yes' \
		# 	&& osascript -e 'tell application "Revisions" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Revisions.$INSTALLED_VERSION.app"
fi

echo "$NAME: installing $MNTPNT/$INSTALL_TO:t to $INSTALL_TO"

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installed $INSTALL_TO successfully"

	[[ "$LAUNCH" == "yes" ]] && open "$INSTALL_TO" && echo "$NAME: re-launched $INSTALL_TO"

	diskutil eject "$MNTPNT"

else
	echo "$NAME: Installation failed (\$EXIT = $EXIT)"

fi


exit 0
#
#EOF
