#!/bin/zsh
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-10-03

# @NOTDONE @TODO - the installation part of this could use some work

NAME="$0:t:r"

INSTALL_TO='/Applications/iTerm.app'

CURRENT=($(curl -sfL https://iterm2.com/appcasts/nightly.xml \
	| tr '[:blank:]' '\012' \
	| tr '"' ' ' \
	| egrep 'sparkle:version|https://iterm2.com/downloads/nightly/iTerm2.*.zip' \
	| sort -u \
	| awk '{print $NF}'))

LATEST_VERSION=`echo "$CURRENT[1]" | sed 's#-nightly##g'`

DOWNLOAD_ACTUAL="$CURRENT[2]"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null | tr -dc '[0-9].' || echo '2.0.0'`


autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"




	# Get to a temp directory
cd "${TMPDIR-/tmp/}"

DIR="$NAME.$RANDOM"

mkdir -p "$DIR"

cd "$DIR"

curl --continue-at - --max-time 3600 --fail --location --referer ";auto" --progress-bar --remote-name "$DOWNLOAD_ACTUAL"

FILENAME="$DOWNLOAD_ACTUAL:t"

	# Unzip download to the current directory
ditto --noqtn -xkv "$FILENAME" .

if [ -e "$INSTALL_TO" ]
then
	# iTerm is already installed
	mv -vn "$INSTALL_TO" "$HOME/.Trash/iTerm.$INSTALLED_VERSION.app"
fi

if [ -e "$INSTALL_TO" ]
then
	# iTerm is STILL installed? Something went wrong

	MSG="iTerm could not be removed from $INSTALL_TO"

	echo "$NAME: $MSG" | tee -a "$HOME/Desktop/$NAME.error.log"

	(( $+commands[growlnotify] )) && pgrep -xq Growl && growlnotify --sticky --appIcon "iTerm" --identifier "$NAME" --message "$MSG" --title "$NAME"

	exit 1
fi

mv -vn iTerm.app "$INSTALL_TO" \
	&& MSG="Updated iTerm to $LATEST_VERSION" \
	&& echo "$NAME: $MSG" \
	&& (( $+commands[growlnotify] )) && pgrep -xq Growl && growlnotify --sticky --appIcon "iTerm" --identifier "$NAME" --message "$MSG" --title "$NAME"



exit
#
#EOF
