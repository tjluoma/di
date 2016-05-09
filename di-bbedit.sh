#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

NAME="$0:t:r"

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

INSTALL_TO='/Applications/BBEdit.app'

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

FILENAME="$HOME/Downloads/BBEdit-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "BBEdit" && pkill "BBEdit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/BBEdit.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

# ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

ditto "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

diskutil eject "$MNTPNT"


exit 0
#EOF
