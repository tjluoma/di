#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Dropbox
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-14

NAME="$0:t:r"

INSTALL_TO='/Applications/Dropbox.app'

HOMEPAGE="https://www.dropbox.com"

DOWNLOAD_PAGE="https://www.dropbox.com/download?plat=mac&full=1"

SUMMARY="It’s a folder that syncs. (See http://qr.ae/TUNeCr if you need more explanation.)"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

function msg {
	echo "$NAME: $@"
}

function die {
	msg "[die] $@"
	exit 1
}

## I found this URL via https://github.com/Homebrew/homebrew-cask/blob/master/Casks/dropbox.rb

DL_URL='https://www.dropbox.com/download?plat=mac&full=1'

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Check the website for the latest version number
#

## Note: Do not use Safari UA here, it will fail
## This gives the actual URL to download, which should look something like this:
#
# https://clientupdates.dropboxstatic.com/dbx-releng/client/Dropbox%2053.4.67.dmg
#
## 2019-03-02:
## Dropbox also seems to use this for downloading specific, full installers:
## https://www.dropbox.com/downloading?build=68.3.95&plat=mac&type=full

URL=$(curl -sfL --head "$DL_URL" | awk -F' |\r' '/^.ocation: /{print $2}' | tail -1)

if [[ "$URL" == "" ]]
then
	die "$NAME: URL is empty. Cannot continue."
	exit 1
fi

# This looks at the URL and extracts the version number from it
LATEST_VERSION=$(echo "$URL:t:r" | sed 's#Dropbox%20##g')

if [[ "$LATEST_VERSION" == "" ]]
then
	die "$NAME: LATEST_VERSION is empty. Cannot continue."
	exit 1
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Get the version number for the installed version of Dropbox
#

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		msg "Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		msg "Installed version ($INSTALLED_VERSION) is ahead of official version ($LATEST_VERSION)"
		exit 0
	fi

	msg  "Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Download File
#

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading $URL to $FILENAME:"

curl --fail \
   \
   --continue-at - \
   --location \
   --output "$FILENAME" \
	"$URL"

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Mount DMG
#

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')


if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty" >>/dev/stderr
	exit 1
else
	echo "$NAME: MNTPNT is '$MNTPNT'."
fi


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Open app (which is an installer,
#		so unlike most DMGs, we don't have to do anything else)
#

if [ -e "$MNTPNT/Dropbox.app" ]
then
   open "$MNTPNT/Dropbox.app"


	EXIT="$?"

	if [[ "$EXIT" == "0" ]]
	then
		# the 'open' command, if it works, will take care of the rest of the
		# installation process.

		exit 0

	else

		if [[ -e "$INSTALL_TO" ]]
		then

			TRASH="$HOME/.Trash"

				# Quit app, if running
				# normally we would use 'osascript' for this, but Dropbox now refuses to
				# quit when asked politely, so we use 'pkill' instead
			pgrep -xq "$INSTALL_TO:t:r" \
			&& LAUNCH='yes' \
			&& pkill -f "$INSTALL_TO/Contents/MacOS/Dropbox"

				# move installed version to trash
			echo "$NAME: moving old installed version to '$TRASH'..."
			mv -f "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

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

	fi


else
	die "Did not find anything at $MNTPNT/Dropbox.app"
	exit 1

fi

exit 0

## 2018-07-14 - This is old, but it used to be the last part of the 'curl' command
#   "https://dl.dropboxusercontent.com/u/17/Dropbox%20${LATEST_VERSION}.dmg"

#EOF
