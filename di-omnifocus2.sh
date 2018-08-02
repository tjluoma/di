#!/bin/zsh -f
# Purpose: Download and install the latest OmniFocus 2 (OmniFocus 3 is due soon)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-26

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniFocus.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

## Note: Downloads are available in tbz2 and dmg but dmg has EULA so I use tbz2

# Don't indent or you'll break 'sed'
INFO=($(curl -sfL "http://update.omnigroup.com/appcast/com.omnigroup.OmniFocus2/" 2>&1 \
| sed 's#<#\
<#g' \
| tr -s ' ' '\012' \
| egrep '<omniappcast:marketingVersion>|url=.*\.tbz2' \
| head -2 \
| tr -s '>|"' ' ' \
| awk '{print $NF}'))

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null`

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

FILENAME="$HOME/Downloads/OmniFocus-$LATEST_VERSION.tbz2"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/OmniFocus.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

tar -x -C "$INSTALL_TO:h" -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation of $INSTALL_TO successful"

else
	echo "$NAME: tar failed (\$EXIT = $EXIT)"

	exit 1
fi


## 2018-07-22 - I don't know if this would actually work to license a copy of OmniFocus which hasn't been licensed through the app itself.
INSTALLED_LICENSE_DIR="$HOME/Library/Containers/com.omnigroup.OmniFocus2/Data/Library/Application Support/Omni Group/Software Licenses/"

if [[ -d "$INSTALLED_LICENSE_DIR" ]]
then
	INSTALLED_LICENSE_FILE=$(find "$INSTALLED_LICENSE_DIR" -type f -iname \*.omnilicense -print 2>/dev/null)

	if [[ "$INSTALLED_LICENSE_FILE" != "" ]]
	then
		echo "$NAME: Found license file for OmniFocus 2 in \"$INSTALLED_LICENSE_DIR\"."
		exit 0
	fi
fi

mkdir -p "$LICENSE_DIR"

MY_LICENSE_FILE="$HOME/Dropbox/dotfiles/licenses/omnifocus/OmniFocus-908786.omnilicense"

if [[ -e "$MY_LICENSE_FILE" ]]
then
	cp -vn "$MY_LICENSE_FILE" "$INSTALLED_LICENSE_DIR/" && echo "$NAME: Installed license file." && exit 0
fi


exit 0

#EOF
