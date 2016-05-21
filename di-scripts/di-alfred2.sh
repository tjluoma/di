#!/bin/zsh -f
# Purpose: download and install alfred, or update it if already installed
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-10

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

LAUNCH='no'

INSTALL_TO='/Applications/Alfred 2.app'

	# Note that we are using the Build Number/CFBundleVersion for Alfred,
	# because that changes more often than the CFBundleShortVersionString
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`


# XML_FEED='https://cachefly.alfredapp.com/updater/info.plist'

XML_FEED='https://cachefly.alfredapp.com/updater/prerelease.plist'


INFO=($(curl -sfL $XML_FEED \
	| egrep -A1 '<key>version</key>|<key>build</key>|<key>location</key>' \
	| egrep '<string>|<integer>' \
	| head -3 \
	| awk -F'>|<' '//{print $3}'))

MAJOR_VERSION="$INFO[1]"
LATEST_VERSION="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

FILENAME="$HOME/Downloads/Alfred-${MAJOR_VERSION}-${LATEST_VERSION}.zip"


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



echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Alfred 2" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Alfred 2" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Alfred 2.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"


[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

# [[ "$LAUNCH_PREFS" = "yes" ]] && open -a "$INSTALL_TO/Contents/Preferences/Alfred Preferences.app"



exit 0
#EOF
