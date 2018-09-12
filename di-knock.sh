#!/bin/zsh -f
# Purpose: Download and install the latest version of Knock
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

INSTALL_TO='/Applications/Knock.app'

XML_FEED='https://knock-updates.s3.amazonaws.com/Knock.xml'

HOMEPAGE="http://www.knocktounlock.com"

# aka http://knock-updates.s3.amazonaws.com/Knock.zip
DOWNLOAD_PAGE="http://knocktounlock.com/download"

SUMMARY="You keep your iPhone with you all the time. Now you can use it as a password. You never have to open the app — just knock on your phone twice, even when it’s in your pocket, and you're in."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

FORCE='no'

for ARGS in "$@"
do
	case "$ARGS" in
		-f|--force)
				FORCE='yes'
				shift
		;;


		-*|--*)
				echo "	$NAME [warning]: Don't know what to do with arg: $1"
				shift
		;;

	esac

done # for args

####################################################################################################
##
##	Knock requires a Mac which has Bluetooth 4.0 or later, the so-called Low Power BT
##		I have at least 2 Macs which don't support this
##

if [ "$FORCE" != "yes" ]
then

		# This should be '4' or greater
	BLUETOOTH_VERSION=`system_profiler -detailLevel full SPBluetoothDataType | awk -F' ' '/LMP Version/{print $3}' | cut -d. -f 1`

	if [ "$BLUETOOTH_VERSION" -ge "4" ]
	then
		echo "$NAME: SUCCESS: This Mac support Bluetooth version 4 or greater"

	elif [ "$BLUETOOTH_VERSION" -lt "4" ]
	then

		echo "$NAME: FAILURE: This Mac does not support Bluetooth version 4 or greater (Version = $BLUETOOTH_VERSION)"

		echo "$NAME: You can use '--force' to bypass this check"

		exit 1

	else

		echo "$NAME: It is not known whether this Mac supports Bluetooth version 4 or later, as required by Knock"

		echo "$NAME: You can use '--force' to bypass this check"

		exit 1

	fi

fi # if not bypassed by --force

####################################################################################################

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString|url=' \
		| sed 's#<sparkle:shortVersionString>##g; s#</sparkle:shortVersionString>##g; s#url="##g; s#"$##g '))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`


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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

# No RELEASE_NOTES_URL. The app is basically EOL as far as I can tell.

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Knock" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Knock" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Knock.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

exit 0
#EOF
