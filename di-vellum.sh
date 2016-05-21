#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-09-24

NAME="$0:t:r"

DIR="$HOME/Downloads"

INSTALL_TO='/Applications/Vellum.app'

INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null || echo 0`

LATEST_VERSION=`curl -sfL "https://get.180g.co/updates/vellum/" | tr -s ' ' '\012' | awk -F'"' '/shortVersionString/{print $2}'`

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/$NAME.$HOST.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

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


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		This is where we do the actual download
#

DL_URL=`curl -sfL "https://get.180g.co/updates/vellum/" | tr -s ' ' '\012' | awk -F'"' '/^url/{print $2}'`

DL_URL=`echo $DL_URL | sed 's#https:/180g#https://180g#g'`

FILENAME="$DIR/Vellum-$LATEST_VERSION.zip"

echo "$NAME: Saving $DL_URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$DL_URL" 2>/dev/null


[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && exit 0


if [ -e "$INSTALL_TO" ]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Vellum.$INSTALLED_VERSION.app"
fi

ditto --noqtn -v -xk "$FILENAME" "$INSTALL_TO:h"

exit
#
#EOF
