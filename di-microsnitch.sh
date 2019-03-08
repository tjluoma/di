#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-02-16

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

PLIST_URL="https://sw-update.obdev.at/update-feeds/microsnitch-1.plist"

zmodload zsh/datetime

TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

PLIST_FILE="$HOME/.Trash/$NAME.$TIME.plist"

curl -sfLS "$PLIST_URL" > "$PLIST_FILE"

# BundleVersion
# BundleShortVersionString
# ReleaseNotesURL
# DownloadURL

echo $PLIST_FILE

# @TODO - finish


exit 0
#EOF
