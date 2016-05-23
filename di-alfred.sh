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

INSTALL_TO='/Applications/Alfred 3.app'

	# Note that we are using the Build Number/CFBundleVersion for Alfred,
	# because that changes more often than the CFBundleShortVersionString
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`


if [ -e "$HOME/.di-alfred-prefer-betas" ]
then
		## this is for betas 
	XML_FEED='https://www.alfredapp.com/app/update/prerelease.xml'
	CHANNEL='Beta'

else
		## THis is for official, non-beta versions
	XML_FEED='https://www.alfredapp.com/app/update/general.xml'
	CHANNEL='Official'
fi

echo "$NAME: Checking for $CHANNEL updates..."

INFO=($(curl -sfL $XML_FEED \
	| egrep -A1 '<key>version</key>|<key>build</key>|<key>location</key>' \
	| egrep '<string>|<integer>' \
	| head -3 \
	| awk -F'>|<' '//{print $3}'))

BUILD="$INFO[1]"
URL="$INFO[2]"
MAJOR_VERSION="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

FILENAME="$HOME/Downloads/Alfred-${MAJOR_VERSION}-${BUILD}.zip"


 if [[ "$BUILD" == "$INSTALLED_VERSION" ]]
 then
 	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
 	exit 0
 fi

autoload is-at-least

 is-at-least "$BUILD" "$INSTALLED_VERSION"
 
 if [ "$?" = "0" ]
 then
 	echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $BUILD"
 	exit 0
 fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $BUILD)"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Alfred 3" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Alfred 3" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Alfred 3.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/" \
&& echo "$NAME: Successfully installed"


exit 0
#EOF
