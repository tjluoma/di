#!/bin/zsh -f
# Download and install (or update) Xquartz
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2014-06-10
#
## In case you need them:
# GENERAL_URL='https://xquartz.macosforge.org/landing/'
# DOWNLOAD_URL='http://xquartz.macosforge.org/trac/wiki/Releases'

NAME="$0:t:r"

zmodload zsh/datetime

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

APP_PATH='/Applications/Utilities/XQuartz.app'

INSTALLED_VERSION=`defaults read "${APP_PATH}/Contents/Info.plist" "CFBundleVersion" 2>/dev/null || echo '0'`

CACHE='/usr/local/install/xquartz.txt'

########################################################################################################################

function update_cache {

	rm -f "$CACHE"

	UPDATES_URL='http://xquartz.macosforge.org/downloads/sparkle/release.xml'

	echo "$NAME: Updating cache at `timestamp`"

	INFO=($(curl -sfL "$UPDATES_URL" | tr -s ' ' '\012' | egrep 'sparkle:version=|url=' | head -2 | awk -F'"' '/^/{print $2}'))

	echo "$NAME: cache update finished at `timestamp`"

	DOWNLOAD_ACTUAL="$INFO[1]"

	LATEST_VERSION="$INFO[2]"

	if [ "$LATEST_VERSION" = "" -o "$DOWNLOAD_ACTUAL" = "" ]
	then
		echo "$NAME: Failed to update cache (no response from $UPDATES_URL)"
		exit 0
	else

		echo "$EPOCHSECONDS $LATEST_VERSION $DOWNLOAD_ACTUAL" > "$CACHE"
	fi

}

########################################################################################################################

if [ -e "$CACHE" ]
then

	CACHE_TIME=`awk '{print $1}' "$CACHE"`

	DIFF=$(($EPOCHSECONDS - $CACHE_TIME))

	if [ "$DIFF" -gt "86400" ]
	then
			# If we get here the cache needs to be updated
		echo "$NAME: Updating $CACHE"
		update_cache
	else
			# if we get here, we can use the cached values

			echo "$NAME: Using cache at $CACHE"

			DOWNLOAD_ACTUAL=`awk '{print $3}' "$CACHE"`

			LATEST_VERSION=`awk '{print $2}' "$CACHE"`
	fi

else
	update_cache
fi




########################################################################################################################



FILENAME="XQuartz-$LATEST_VERSION.dmg"

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/metalog/$NAME/$HOST/$TIME.txt"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { 	echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

function msg {

	MSG="$@"

	log "$MSG"

	if (( $+commands[growlnotify] ))
	then
		growlnotify --appIcon "XQuartz" --identifier "install-update-xquartz" --message "$@" --title "Install/Update XQuartz"
	fi
}

function msgs {

	MSG="$@"

	log "$MSG"

	if (( $+commands[growlnotify] ))
	then
		growlnotify --sticky --appIcon "XQuartz" --identifier "install-update-xquartz" --message "$@" --title "Install/Update XQuartz"
	fi
}

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




# if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]
# then
# 		log "$APP_PATH:t is up-to-date ($INSTALLED_VERSION ~ $LATEST_VERSION)"
# 		exit 0
# else
# 			# Update Needed
# 		msgs "$APP_PATH:t is outdated ($INSTALLED_VERSION vs $LATEST_VERSION)"
# fi

cd "$HOME/Downloads" || cd "$HOME/Desktop" || cd "$HOME" || cd /tmp

##
## 2016-03-19 - the size checking code seems to causing an infinite loop
##
# REMOTE_SIZE=`curl -sL --head "${DOWNLOAD_ACTUAL}" | awk -F' ' '/Content-Length/{print $NF}'| tr -dc '[0-9]'`
#
#zmodload zsh/stat
##
# function get_local_size
# {
#
# 	LOCAL_SIZE=$(zstat -L +size "$FILENAME" 2>/dev/null)
#
# }
#
# get_local_size
#
# while [ "$LOCAL_SIZE" -lt "$REMOTE_SIZE" ]
# do
#
# 	curl -C - --max-time 3600 --fail --location --referer ";auto" --progress-bar --remote-name "${DOWNLOAD_ACTUAL}"
#
# 	get_local_size
#
# done

echo "$NAME: Saving $DOWNLOAD_ACTUAL to $PWD/$FILENAME"
curl -C - --max-time 3600 --fail --location --referer ";auto" --progress-bar --output "${FILENAME}" "${DOWNLOAD_ACTUAL}"


[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && exit 0



MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep -A 1 '<key>mount-point</key>' | tail -1 | sed 's#</string>.*##g ; s#.*<string>##g')

if [ "$MNTPNT" = "" ]
then
	msgs "MNTPNT is empty"
	exit 0
fi

PKG=`find "$MNTPNT" -maxdepth 1 -iname \*.pkg`

if [ "$PKG" = "" ]
then
	msgs "PKG is empty"
	exit 0
fi

msgs "Installing $PKG (this may take awhile...)"

sudo installer -verbose -pkg "$PKG" -target / -lang en 2>&1 | tee -a "$LOG"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	msg "Successfully installed XQuartz.app version $LATEST_VERSION"

	COUNT='0'

	while [ -e "$MNTPNT" ]
	do
		((COUNT++))

		if [ "$COUNT" -gt "10" ]
		then
			exit 0
		fi
			# unmount the DMG
		diskutil eject "$MNTPNT" || sleep 5
	done

	if [ ! -e "$MNTPNT" ]
	then
		msg "Unmounted $MNTPNT"
	fi

	exit 0

else
	msg "FAILED to install XQuartz.app version $LATEST_VERSION (exit = $EXIT)"
	exit 1
fi


exit
#
#EOF
