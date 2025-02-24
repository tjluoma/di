#!/usr/bin/env zsh -f
# Purpose: Download and install latest version of Subtitlesapp.com
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-05-01

NAME="$0:t:r"

INSTALL_TO='/Applications/Subtitles.app'

HOMEPAGE="https://subtitlesapp.com/"

DOWNLOAD_PAGE="https://subtitlesapp.com/download/mac"

SUMMARY="The easiest way to download subtitles."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

XML_FEED='https://subtitlesapp.com/updates.xml'

	# this XML file is... unusual. It's a huge blob of XML, most of which is XML-ified HTML, so
	# we use 'tidy' to force it into something more easily readable

	# CFBundleShortVersionString and CFBundleVersion: 3.2.11 are identical, so no need to check both

INFO=($(curl -sfL "$XML_FEED" \
	| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
	| sed 's#&lt;#<#g ; s#&gt;#>#g ' \
	| fgrep 'sparkle:version=' \
	| head -1 \
	| tr -s ' ' '\012' \
	| sort \
	| egrep 'sparkle:version=|url=' \
	| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Trying backup method to find URL and LATEST_VERSION"

	URL=`curl -sfL --head 'http://subtitlesapp.com/download/' | awk -F' |\r' '/^Location:/{print $2}' | tail -1`

	LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

fi

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then

	echo "$NAME: Cannot continue. Bad data from $XML_FEED:
	INFO: $INFO
	URL: $URL
	LATEST_VERSION: LATEST_VERSION
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n" ;
	curl -sfL "$XML_FEED" \
		| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
		| sed 's#&lt;#<#g ; s#&gt;#>#g ' \
		| sed '1,/<item>/d; /<br><h3>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: XML_FEED <${RELEASE_NOTES_URL}>" ) | tee "$FILENAME:r.txt"

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
