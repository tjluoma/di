#!/usr/bin/env zsh -f
# Purpose: Download the latest version of Soundnode from <http://www.soundnodeapp.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-06-02

NAME="$0:t:r"

echo "$NAME: this is re-downloading version 0.6.5 as Soundnode-7.0.11"

## @TODO The numbering scheme has changed dramatically. Presumably as v7 switched to electron and
## the developer wants to get everything on the same version number?

## 2018-08-02 - ok, for some reason there's a '7.0.0' tag_name, when all the rest are like this:
#     "tag_name": "0.6.5",
#     "tag_name": "0.6.4",
#     "tag_name": "0.6.3",
#     "tag_name": "0.6.2",
#     "tag_name": "0.6.1",
#     "tag_name": "0.6.0",
#     "tag_name": "0.5.9",
## So I'm just excluding that one for 'latest-version' checking purposes, because otherwise this will constantly run
## and replace itself with new versions that aren't really new. Not sure what else to do.

## See LATEST_VERSION= below

exit 1


















INSTALL_TO="/Applications/Soundnode.app"

HOMEPAGE="http://www.soundnodeapp.com/"

DOWNLOAD_PAGE="http://www.soundnodeapp.com/downloads/mac/Soundnode.zip"

SUMMARY="An opensource SoundCloud app for desktop."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

URL='http://www.soundnodeapp.com/downloads/mac/Soundnode.zip'

LATEST_VERSION=`curl -sfL https://api.github.com/repos/Soundnode/soundnode-app/releases \
				| fgrep tag_name \
				| fgrep -v '"tag_name": "7.0.0",' \
				| head -1 \
				| tr -dc '[0-9].'`

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date ($LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Here’s the download section
#

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="https://github.com/Soundnode/soundnode-app/releases/tag/$LATEST_VERSION"

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION/$LATEST_BUILD):" ;
	curl -sfLS "$RELEASE_NOTES_URL" \
	| sed '1,/release-header/d; /release-body/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| LC_ALL=C sed 's#file:///#https://github.com/#g' ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading $URL to $FILENAME"

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

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.$$.app"

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
#EOF
