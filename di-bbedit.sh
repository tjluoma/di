#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

NAME="$0:t:r"
APPNAME="BBEdit"

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# INFO=($(curl -sfL 'https://versioncheck.barebones.com/BBEdit.cgi' \
# | egrep -A1 '<key>SUFeedEntryShortVersionString</key>|<key>SUFeedEntryUpdateURL</key>' \
# | fgrep '<string>' \
# | tail -2 \
# | sed 's#.*<string>##g; s#</string>.*##g'))
# 
# LATEST_VERSION="$INFO[1]"
# 
# URL="$INFO[2]"

################################################################################################################
## 2016-02-04 - the URL seems to lead to a 'BBEdit_11.5.cpgz' file but I want the dmg 
## so I look for the DMG and then extract the version number from the filename 

URL=`curl -sfL 'https://versioncheck.barebones.com/BBEdit.cgi' \
| egrep '\.dmg</string>$' \
| tail -1 \
| sed 's#.*<string>##g; s#</string>##g'`
	
LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`
##
################################################################################################################

INSTALL_TO="/Applications/$APPNAME.app"

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

FILENAME="$HOME/Downloads/${APPNAME//[[:space:]]/}-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
	pgrep -qx "$APPNAME" && LAUNCH='yes' && killall "$APPNAME"
	mv -f "$INSTALL_TO" "$HOME/.Trash/$APPNAME.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

# ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

ditto "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"
	
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

diskutil eject "$MNTPNT"


exit 0
#EOF
