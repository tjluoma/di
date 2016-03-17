#!/bin/zsh
# Purpose: download and install (or update, if needed) Flash for OS X
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-07-12


	# URL found via
	# https://forums.adobe.com/thread/938109?start=0&tstart=0
	# Where can I get Flash Player 11 in PKG format to distribute to Macs over our intranet?
	# If the URL changes but the format stays the same, you should be able to just
	# change it here.

# URL='http://www.adobe.com/products/flashplayer/distribution3.html'

##################################################################################################################################

NAME="$0:t:r"

zmodload zsh/datetime	# needed for EPOCHSECONDS

zmodload zsh/stat		# needed for file size

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/$NAME.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME: $@ [`timestamp` on $HOST]" | tee -a "$LOG" }

################################################################################################################
#
# See http://oit.ncsu.edu/macintosh/adobe-flash-os-x-unattended-silent-install
#
CFG="/Library/Application Support/Macromedia/mms.cfg"

if [[ ! -e "$CFG" ]]
then

TMPFILE=`mktemp /tmp/$LOGNAME.XXXXXXX`

cat <<EOINPUT > "$TMPFILE"
AutoUpdateDisable=0
SilentAutoUpdateEnable=1
AutoUpdateInterval=1
DisableProductDownload=0
SilentAutoUpdateVerboseLogging=0
EOINPUT

	# Create directory if needed
[[ ! -d "$CFG:h" ]] \
	&& sudo mkdir -p "$CFG:h" \
		&& log "Created directory: $CFG:h"

sudo mv -vf "$TMPFILE" "$CFG" \
	&& sudo chmod 644 "$CFG" \
		&& sudo chown root:wheel "$CFG" \
			&& log "Created $CFG (chmod 644/chown root)"

fi
################################################################################################################
#
#	Check current version on website
#
# log "Checking version info from ..."

## 2014-10-03 this is getting a bad result:
## Flash Player 15.0.0.152 (Win Firefox and Mac); 15.0.0.167 (Win IE)</span>
## so I'm trying something new
# LATEST_VERSION=`curl -sL "$URL" | egrep 'Flash Player.* and Mac' | tr -dc '[0-9].'`

# LATEST_VERSION=`curl -sL "$URL" | egrep 'Flash Player.* Mac' | sed 's# Mac.*##g' | tr -dc '[0-9].'`

	## 2015-08-31 -
	## Flash Player 18.0.0.232 (Win and Mac)
	## Now trying 'head -1'
# LATEST_VERSION=`curl -sL "$URL"  | egrep 'Flash Player.* Mac' | sed 's# Mac.*##g' | head -1 |  tr -dc '[0-9].'`

LATEST_VERSION=`curl --silent --fail --location \
	'http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml' \
| awk -F'"' '/version=/{print $2}' \
| tr ',' '.'`

if [[ "$LATEST_VERSION" = "" ]]
then
	log "LATEST_VERSION is empty"
	exit 0
fi

## 2014-10-03 the length check is intended to see if we are getting two sets of results as above
## 15 characters allows for a version number xxx.xxx.xxx.xxx
LENGTH=`echo -n "$LATEST_VERSION" | wc -c | tr -dc '[0-9]'`

if [ "$LENGTH" -gt "15" ]
then
	log "$LATEST_VERSION is greater than 15 characters: $LENGTH"
	exit 0
fi


##################################################################################################################################
#
#	Check local (installed version) if any
#

PLIST='/Library/Internet Plug-Ins/Flash Player.plugin/Contents/version.plist'

if [ -e "$PLIST" ]
then
		# if the plist is installed, check the version number
	LOCAL_VERSION=`defaults read "$PLIST" CFBundleShortVersionString`

	if [ "$LOCAL_VERSION" = "$LATEST_VERSION" ]
	then
		log "Flash is up to date $LATEST_VERSION = $LOCAL_VERSION"
		mv -f "$LOG" "$HOME/.Trash/"
		exit 0
	fi
fi


# 2015-01-13: If we get here, an update is available.
# Send a push notification so I can see check to see if it works

po.sh "$NAME: $LOCAL_VERSION outdated vs $LATEST_VERSION"

##################################################################################################################################
#
#	Define function for later
#
function do_download
{
	REMOTE_SIZE=`curl -sfL --head "${PKG_URL}" | awk -F' ' '/Content-Length:/{print $NF}' | tr -dc '[0-9]'`

	if [ "$REMOTE_SIZE" = "" ]
	then
		log "Failed to get Content-Length for $PKG_URL"
		exit 0
	fi

	if [ -e "$FILENAME" ]
	then
		log "Continuing download of $PKG_URL to $FILENAME"
			# if the file is already there, continue download
		curl -sfL --progress-bar --continue-at - --output "$FILENAME" "$PKG_URL"
	else
		log "Downloading $PKG_URL to $FILENAME"
			# if the file is NOT there, don't try to continue
		curl -sfL --progress-bar --output "$FILENAME" "$PKG_URL"
	fi

	SIZE=$(zstat -L +size "$FILENAME")

	if [ "$SIZE" != "$REMOTE_SIZE" ]
	then
		log "Download of $PKG_URL to $FILENAME failed. File size mismatch: expected $REMOTE_SIZE, have $SIZE"
		exit 0
	fi
}

##################################################################################################################################
#
#	If we get here we need to download/install new version
#

		### This is the only 'hacky' bit: it depends on the format of the web page not changing too much.
		###
		### If you have `lynx` installed, this might be a little 'safer':
		# PKG_URL=`lynx -listonly -dump -nomargins -nonumbers "$URL" | fgrep -i pkg.dmg | head -1`

		# Get the page source HTML,
		#	replace any ' or " with a new line,
		#	and grep for 'osx' followed by 'pkg'
		#	and then take the first response
		# PKG_URL=`curl -sfL "$URL" | tr '"|\047' '\012' | egrep 'osx.*pkg' | head -1`

## 2015-10-20 - replacing the commented-out block immediately above here


	# Take the version number and just look at the number before the first "."
MAJOR_VERSION=`echo "$LATEST_VERSION" | cut -d . -f 1`

PKG_URL="https://fpdownload.macromedia.com/get/flashplayer/current/licensing/mac/install_flash_player_${MAJOR_VERSION}_osx_pkg.dmg"

HTTP_STATUS=`curl -sfL --head "$PKG_URL" | awk -F' ' '/^HTTP/{print $2}'`

if [[ "$HTTP_STATUS" != "200" ]]
then
		# If we don't get anything, we can't proceed.
		# This is probably an indication that PKG_URL needs to be verified as still correct
	log "HTTP_STATUS for $PKG_URL is $HTTP_STATUS"
	exit 1
fi

	# We want to save the download with a filename which will include the version number.
# FILENAME="$HOME/Downloads/FlashPlayer-$LATEST_VERSION.dmg"

FILENAME="${TMPDIR-/tmp/}FlashPlayer-$LATEST_VERSION.dmg"

	# This is where we do the download (if it isn't already downloaded)
if [ -s "$FILENAME" ]
then
	SIZE=$(zstat -L +size "$FILENAME")

	if [ "$SIZE" = "$REMOTE_SIZE" ]
	then
		log "$FILENAME is already completely downloaded"
	else
		do_download
	fi
else
	do_download
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		This is where we mount the DMG we have downloaded
#


#     hdiutil attach "$flash_dmg" -mountpoint "$TMPMOUNT" -nobrowse -noverify -noautoopen


MNTPNT=$(hdiutil attach -nobrowse -noverify -noautoopen -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" = "" ]]
then
	log "MNTPNT is empty"
	exit 1
fi

	# This is where we look for the .pkg file in the mounted DMG
PKG=`find "$MNTPNT" -iname \*.pkg -maxdepth 1`

if [[ "$PKG" = "" ]]
then
	log "PKG is empty"
	exit 1
fi

sudo installer -pkg "$PKG" -target / -lang en 2>&1 | tee -a "$LOG"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	log "Installation successful"

	echo "$NAME [$HOST]: Updated to $LATEST_VERSION" | slackcat -tee --channel "$HOST"

	diskutil eject "${MNTPNT}"

	DIR="/Volumes/Flash Player"

	if [ -e "$DIR" ]
	then
		if (( $+commands[unmount.sh] ))
		then
				unmount.sh "$DIR"
		else
				diskutil eject "$DIR"
		fi
	fi

else
	log "Installation failed (\$EXIT = $EXIT)"

fi

exit 0
#
#EOF
