#!/bin/zsh -f
# Purpose: Download and install the latest version of Dropbox
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	Sat, Jul 14, 2018 4:11

NAME="$0:t:r"

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
	po.sh "[die] $@"
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

URL=$(curl -sfL --head "$DL_URL" | awk -F' ' '/^.ocation: /{print $2}' | tail -1 | tr -d '\r')

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

INSTALL_TO='/Applications/Dropbox.app'

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
		msg "Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
		exit 0
	fi

	msg  "Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Download File
#

FILENAME="$HOME/Downloads/Dropbox-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading $URL to $FILENAME:"

curl --fail \
   --progress-bar \
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

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Open app (which is an installer,
#		so unlike most DMGs, we don't have to do anything else)
#

if [ -e "$MNTPNT/Dropbox.app" ]
then
   open "$MNTPNT/Dropbox.app"
else
	die "Did not find anything at $MNTPNT/Dropbox.app"
	exit 1

fi

exit 0

## 2018-07-14 - This is old, but it used to be the last part of the 'curl' command
#   "https://dl.dropboxusercontent.com/u/17/Dropbox%20${LATEST_VERSION}.dmg"

#EOF
