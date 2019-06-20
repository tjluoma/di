#!/bin/zsh -f
# Purpose: Download and install Tower 2 or 3 (note that Tower 3 requires an annual subscription)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2018-08-21

NAME="$0:t:r"

INSTALL_TO='/Applications/Tower.app'

HOMEPAGE="https://www.git-tower.com/mac"

DOWNLOAD_PAGE="https://www.git-tower.com/download/mac"

SUMMARY="Tower helps you master version control with Git. (NOTE: Version information is for v2 because v3 is subcription that I haven’t signed up for.)"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

OS_VER=`sw_vers -productVersion`

function use_v2 {
	XML_FEED="https://updates.fournova.com/updates/tower2-mac/stable/?os_version=$OS_VER"
	ASTERISK='(Note that version 3 is now available.)'
}

function use_v3 {

		# if you want to install beta releases
		# create a file (empty, if you like) using this file name/path:
	PREFERS_BETAS_FILE="$HOME/.config/di/tower-prefer-betas.txt"

	if [[ -e "$PREFERS_BETAS_FILE" ]]
	then
		NAME="$NAME (beta releases)"
		XML_FEED="https://updates.fournova.com/updates/tower3-mac/beta/?os_version=$OS_VER"
	else
		# This is for non-beta
		XML_FEED="https://updates.fournova.com/updates/tower3-mac/stable/?os_version=$OS_VER"
	fi
}

if [[ -e "$INSTALL_TO" ]]
then
		# if v2 is installed, check that. Otherwise, use v3
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "2" ]]
	then
		use_v2
	else
		use_v3
	fi
else
	if [ "$1" = "--use2" -o "$1" = "-2" ]
	then
		use_v2
	else
		use_v3
	fi
fi

INFO=($(curl -sSfL "${XML_FEED}" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
		| head -3 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read $INSTALL_TO/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '0'`

	 if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	 then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| fgrep '<sparkle:releaseNotesLink>' \
		| head -1 \
		| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')

	( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<div id="content-wrapper">/d;' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0

#
#EOF
