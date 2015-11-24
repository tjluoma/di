#!/bin/zsh
# Purpose: Download and install new version of Calibre
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-07-25

NAME="$0:t:r"

zmodload zsh/stat

##

DOWNLOAD_ONLY='no'

for ARGS in "$@"
do
	case "$ARGS" in
		-d|--download)
				DOWNLOAD_ONLY='yes'
				shift
		;;

		-*|--*)
				echo "	$NAME [warning]: Don't know what to do with arg: $1"
				shift
		;;

	esac

done # for args

##

INSTALL_TO="/Applications/calibre.app"

CURRENT_VERSION=`curl -sfL 'http://status.calibre-ebook.com/latest'`

	# curent version is empty, something went wrong
[[ "$CURRENT_VERSION" = "" ]] && exit 0

##

if [ -e '/Applications/calibre.app/Contents/Info.plist' ]
then
	LOCAL_VERSION=`defaults read '/Applications/calibre.app/Contents/Info.plist' CFBundleShortVersionString `
else
	LOCAL_VERSION='0'
fi

	# no update needed
[[ "$CURRENT_VERSION" = "$LOCAL_VERSION" ]] && echo "$NAME: calibre $CURRENT_VERSION is current" && exit 0

##

DOWNLOAD_ACTUAL="http://download.calibre-ebook.com/${CURRENT_VERSION}/calibre-${CURRENT_VERSION}.dmg"

cd '/Volumes/Data/Websites/iusethis.luo.ma/calibre/' 2>/dev/null \
	|| cd "$HOME/BitTorrent Sync/iusethis.luo.ma/calibre/" 2>/dev/null \
	|| cd "$HOME/Downloads/" 2>/dev/null \
	|| cd "$HOME/Desktop/" 2>/dev/null \
	|| cd "$HOME/"

FILENAME="$PWD/$DOWNLOAD_ACTUAL:t"

########################################################################################################################

if [ -e "$FILENAME" ]
then
	LOCAL_SIZE=$(zstat -L +size "$FILENAME")
else
	LOCAL_SIZE='0'
fi

REMOTE_SIZE=$(curl -sfL --head "$DOWNLOAD_ACTUAL" | egrep -i "^Content-Length: " | tail -1  | tr -dc '[0-9]')

MAX_ATTEMPTS="10"
SECONDS_BETWEEN_ATTEMPTS="10"
COUNT=0

while [ "$LOCAL_SIZE" -lt "$REMOTE_SIZE" ]
do

		# increment counter (this is why we init to 0 not 1)
	((COUNT++))

		# check to see if we have exceeded maximum attempts
	if [ "$COUNT" -gt "$MAX_ATTEMPTS" ]
	then

		echo "$NAME: Exceeded $MAX_ATTEMPTS"

		exit 0
	fi

		# don't sleep the first time through the loop
	[[ "$COUNT" != "1" ]] && sleep ${SECONDS_BETWEEN_ATTEMPTS}

	# Do whatever you want to do in the 'while' loop here
	echo "$NAME: Downloading $DOWNLOAD_ACTUAL"
	curl --progress-bar --location --continue-at - --output "$FILENAME" "$DOWNLOAD_ACTUAL"

	LOCAL_SIZE=$(zstat -L +size "$FILENAME")
done

########################################################################################################################

if [ "$DOWNLOAD_ONLY" = "yes" ]
then
	echo "$NAME: Downloaded $DOWNLOAD_ACTUAL to $FILENAME, not installing"
	exit 0
else
	echo "$NAME: Download of $FILENAME from $DOWNLOAD_ACTUAL succeeded."
fi


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Installation
#

# MNTPNT=$(echo -n "Y" \
# 		| hdid -plist "$FILENAME" 2>/dev/null \
# 		| fgrep -A 1 '<key>mount-point</key>' \
# 		| tail -1 \
# 		| sed 's#</string>.*##g ; s#.*<string>##g')

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
 		| fgrep -A 1 '<key>mount-point</key>' \
 		| tail -1 \
 		| sed 's#</string>.*##g ; s#.*<string>##g')


if [ "$MNTPNT" = "" ]
then
	echo "$NAME: Failed to mount $FILENAME"
	exit 1
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Automatically quit and restart calibre
#

PLIST="$HOME/Library/LaunchAgents/com.tjluoma.keeprunning.calibre.plist"

if [ -e "$PLIST" ]
then
	launchctl unload "$PLIST"
fi

# If calibre is running, wait
while [ "`pgrep -x calibre`" != "" ]
do

	MSG='calibre is running. Please quit to continue'

	growlnotify --sticky --appIcon "calibre" --identifier "$NAME" --message "$MSG" --title "$NAME"

	echo "$NAME: $MSG"

	sleep 10
done



if [ -e "$INSTALL_TO" ]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$LOCAL_VERSION.app"
fi

if [ -e "$INSTALL_TO" ]
then
	echo "$NAME: Failed to remove existing $INSTALL_TO"
	exit 1
fi

# growlnotify --sticky --appIcon "calibre" --identifier "$NAME" --message "Installing calibre $CURRENT_VERSION" --title "$NAME"

ditto --noqtn -v "$MNTPNT/calibre.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	MSG="Success! calibre $CURRENT_VERSION installed"

	growlnotify --appIcon "calibre" --identifier "$NAME" --message "$MSG" --title "$NAME"

	echo "$NAME: $MSG"

	if [ -e "$PLIST" ]
	then
		launchctl load "$PLIST"
	fi

else
	echo "$NAME: installation (ditto) failed (\$EXIT = $EXIT)"

	growlnotify --sticky --appIcon "calibre" --identifier "$NAME" --message "FAILED to install calibre $CURRENT_VERSION (EXIT: $EXIT)" --title "$NAME"

	exit 1
fi

	# Try to eject the DMG
diskutil eject "$MNTPNT"

exit
#
#EOF
