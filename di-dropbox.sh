#!/bin/zsh -f

NAME="$0:t:r"

function msg {
		echo "$NAME: $@"
}


die ()
{
	msg "[die] $@"
	po.sh "[die] $@"
	exit 1
}


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Check the website for the latest version number
#

LATEST_VERSION=`curl -A "$UA" -sL 'https://www.dropbox.com/install' |\
				fgrep '<span id="version_str">' |\
				sed 's#.*<span id="version_str">##g ; s# .*##g'`

if [[ "$LATEST_VERSION" == "" ]]
then
 	die "$NAME: LATEST_VERSION is empty. Cannot continue."
    exit 1
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Get the version number for the installed version of Dropbox
#

INSTALLED_VERSION=`defaults read /Applications/Dropbox.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo 0`

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Compare Versions
#

# function version { echo "$@" | awk -F. '{ printf("08%03d%03d%03d\n", $1,$2,$3,$4); }'; }
# 
# if [ $(version ${LATEST_VERSION}) -gt $(version ${INSTALLED_VERSION}) ]
# then
#     msg "Dropbox is out of date: $INSTALLED_VERSION vs $LATEST_VERSION"
# else
# 
#     msg "Dropbox is up to date! [$INSTALLED_VERSION = $LATEST_VERSION]"
#     exit 0
# fi


 if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
 then
 	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
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


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Download File
#

FILENAME="$HOME/Downloads/Dropbox-${LATEST_VERSION}.dmg"



curl --fail \
    --progress-bar \
    --continue-at - \
    --location \
    --output "$FILENAME" \
    "https://dl.dropboxusercontent.com/u/17/Dropbox%20${LATEST_VERSION}.dmg"

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
#		Open app (which is an installer)
#

if [ -e "$MNTPNT/Dropbox.app" ]
then
    open "$MNTPNT/Dropbox.app"
else
	die "Did not find anything at $MNTPNT/Dropbox.app"
	exit 1

fi

#EOF

