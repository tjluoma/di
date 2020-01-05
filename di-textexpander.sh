#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of TextExpander 5 or 6.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-21

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/TextExpander.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/TextExpander.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

HOMEPAGE="https://textexpander.com"

DOWNLOAD_PAGE="https://textexpander.com/cgi-bin/redirect.pl?cmd=download&platform=osx"

SUMMARY="TextExpander lets you instantly insert snippets of text from a repository of emails, boilerplate and other content, as you type – using a quick search or abbreviation. Older versions at https://textexpander.com/textexpander-standalone-apps/"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function use_v5 {
		# This lacks 5.1.5, don't use it --> XML_FEED='https://updates.devmate.com/com.smileonmymac.textexpander.xml'

	XML_FEED=http://smilesoftware.com/appcast/TextExpander5.xml
	USE_VERSION='5'
	ASTERISK='(Note that version 6 is also available.)'
}

## 'https://textexpander.com/cgi-bin/redirect.pl?cmd=download&platform=osx' -->
## https://cdn.textexpander.com/mac/TextExpander_6.5.2.zip

function use_v6 {

	# This seems equivalent. Leaving for future reference, in case it's needed.
	# XML_FEED='https://smilesoftware.com/appcast/update.php?appName=TextExpander&appVersion=6'

	## Betas: http://smilesoftware.com/appcast/TextExpander6-beta.xml

	XML_FEED=http://smilesoftware.com/appcast/TextExpander6.xml
	USE_VERSION='6'
}

if [[ -e "$INSTALL_TO" ]]
then
		# if v5 is installed, check that. Otherwise, use v6
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "5" ]]
	then
		use_v5
	else
		use_v6
	fi
else
	if [ "$1" = "--use5" -o "$1" = "-5" ]
	then
		use_v5
	else
		use_v6
	fi
fi

INFO=($(curl -sSfL "${XML_FEED}" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString|url=' \
		| tail -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

	LAUNCH_HELPER='yes'

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

	# Only show release notes for current version
if [[ "$USE_VERSION" == "6" ]]
then
	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL="$XML_FEED"

		( echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n" ;
			(curl -sfL "$RELEASE_NOTES_URL" | sed '1,/CDATA/d; /<\/ul>/,$d' ;echo '</ul>') \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"
	fi
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TRASH/"

	mv -fv "$FILENAME:r".* "$TRASH/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TRASH}/${NAME}-XXXXXXXX")

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

	osascript -e 'tell application "TextExpander Helper" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$TRASH/'."

	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$TRASH'."

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

[[ "$LAUNCH_HELPER" == "yes" ]] && open "$INSTALL_TO/Contents/Helpers/TextExpander Helper.app"

exit 0
#EOF
