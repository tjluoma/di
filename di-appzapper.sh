#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of AppZapper
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/AppZapper.app'
else
	INSTALL_TO='/Applications/AppZapper.app'
fi

HOMEPAGE="https://www.appzapper.com"

DOWNLOAD_PAGE="https://www.appzapper.com"

SUMMARY="Everybody loves the drag and drop nature of OS X. Drag an app into your applications folder, and it's installed. You'd think it would be that easy to delete an app — just a matter of dragging it to the trash. It's not. Apps install support files that generate clutter. Introducing AppZapper. Simply drag one or more apps onto AppZapper. Then, watch as it finds the extra files and lets you delete them with one click. Zap!"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -gt "11" ]
then
	URL='https://appzapper.com/downloads/appzapper202.zip'
	LATEST_VERSION='2.0.2'
else
		# this version works back to 10.6.2
	URL='https://appzapper.com/downloads/AppZapper2.0.1.zip'
	LATEST_VERSION='2.0.1'
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION="$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)"

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

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

## The app does not seem to be under active development. If that changes, the following might be useful.
## For now, it's just reference
##
# XML_FEED="https://www.appzapper.com/az2appcast.xml"
#
# RELEASE_NOTES_URL='https://www.appzapper.com/az2sparklenotes.html'
#
# INFO=($(curl -sfL "$XML_FEED" \
# 		| tr -s ' ' '\012' \
# 		| egrep 'sparkle:version=|url=' \
# 		| head -2 \
# 		| sort \
# 		| awk -F'"' '/^/{print $2}'))
#
# LATEST_VERSION="$INFO[1]"
#
# URL="$INFO[2]"
#
# 	# If any of these are blank, we should not continue
# if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
# then
# 	echo "$NAME: Error: bad data received:
# 	INFO: $INFO
# 	LATEST_VERSION: $LATEST_VERSION
# 	URL: $URL
# 	"
#
# 	exit 1
# fi
#
# ## 2018-07-17 - as of this writing, the XML_FEED only shows version 2.0.1 but the website shows 2.0.2
# ## I don't know if the app will ever be updated in the future, so
# ## if we get 2.0.1 from the XML_FEED, we're going to silently replace it with 2.0.2
#
# if [[ "$LATEST_VERSION" == "2.0.1" ]]
# then
#
# 	URL="https://appzapper.com/downloads/appzapper202.zip"
#
# 	LATEST_VERSION="2.0.2"
#
# fi
#
# if (( $+commands[lynx] ))
# then
#
# 	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):" ;
# 		lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" ;
# 		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"
#
# fi

#
#EOF
