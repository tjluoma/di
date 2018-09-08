#!/bin/zsh -f
# Purpose: download and install the latest version of Choosy
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-27

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

if [ -e "/Library/PreferencePanes/Choosy.prefPane" -a -e "$HOME/Library/PreferencePanes/Choosy.prefPane" ]
then

	echo "$NAME: Choosy.prefPane is installed at _BOTH_ '/Library/PreferencePanes/Choosy.prefPane' and '$HOME/Library/PreferencePanes/Choosy.prefPane'.
	Please remove one."

	exit 1

elif [[ -e "/Library/PreferencePanes/Choosy.prefPane" ]]
then

	INSTALL_TO="/Library/PreferencePanes/Choosy.prefPane"

else

	INSTALL_TO="$HOME/Library/PreferencePanes/Choosy.prefPane"

fi

XML_FEED='http://www.choosyosx.com/sparkle/feed'

HOMEPAGE="https://www.choosyosx.com"

DOWNLOAD_PAGE="https://www.choosyosx.com"

SUMMARY="Instead of opening links in the default browser, Choosy sends them to the right browser. Every time."

	# sparkle:version= is the only version information available
INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep "sparkle:version=|url=" \
		| head -2 \
		| awk -F'"' '/^/{print $2}'))

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| sed '1,/<description><\!\[CDATA\[/d; /<\/description>/,$d' \
	| awk -F'"' '/http/{print $2}')

URL="$INFO[2]"

LATEST_VERSION="$INFO[1]"

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0`

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

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION:\n" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<h3>Release notes<\/h3>/d; /<h3>Download<\/h3>/,$d' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) \
	| tee -a "$FILENAME:r.txt"

fi

	# Where to save new download
FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

	# Do the download
echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

# Move old version to trash
if [ -e "$INSTALL_TO" ]
then

	pgrep -qx Choosy && pkill Choosy

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	FIRST_INSTALL='no'
else
	FIRST_INSTALL='yes'
fi

	# Install

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

ditto --noqtn -x -k  "$FILENAME" "$INSTALL_TO:h"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation successful to $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi

	# Remove quarantine info (there shouldn't be any, but just in case)
find "$INSTALL_TO" -print | xargs xattr -d com.apple.quarantine 2>/dev/null

### POST INSTALL

if (( $+commands[defaultbrowser] ))
then
	defaultbrowser -set choosy
else
	echo "$NAME: 'defaultbrowser' not found. Download from 'https://codeload.github.com/kerma/defaultbrowser/zip/master'."

	open 'https://codeload.github.com/kerma/defaultbrowser/zip/master'

fi

	# Launch Helper
echo "$NAME: Launching Choosy Helper app"

open -a "$INSTALL_TO/Contents/Resources/Choosy.app"

	# If this is the first time it has been installed, open the preference pane so it can be configured
if [[ "$FIRST_INSTALL" == "yes" ]]
then
		# Launch App
	open "$INSTALL_TO"
fi


exit 0
#
#EOF
