#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Nottingham
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-03

NAME="$0:t:r"

INSTALL_TO='/Applications/Nottingham.app'

HOMEPAGE="https://clickontyler.com/nottingham/"

DOWNLOAD_PAGE="https://downloads-clickonideas.netdna-ssl.com/nottingham/nottingham4_7.zip"

SUMMARY="Nottingham is your very own personal, plain-text wiki. It's a simple and elegant place to store all of your notes, thoughts, and ideas - and then link them together with [[WikiLinks]]. Insanely fast full-text search across even the largest of libraries plus @tags and cross-references means you can organize your notes in any way that suits your own particular preferences."

XML_FEED="http://shine.clickontyler.com/appcast.php?id=39"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INFO=($(curl --location --fail --silent "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep -i '^(url|sparkle:shortVersionString|sparkle:version)=' \
		| head -3 \
		| sort \
		| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	# initial RELEASE_NOTES_URL support for v4

	(curl -sfLS "$XML_FEED" \
 	| awk '/<description/{i++}i==2' \
	| sed -e '/<pubDate>/,$d' -e 's#\<\!\[CDATA\[##g' -e 's#\]\]\>##g' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| sed -e '/./,/^$/!d' -e 's#^ *##g') \
	| tee "$FILENAME:r.txt"

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

	## This feed was for v3
	# XML_FEED="https://shine.clickontyler.com/appcast.php?id=35"

#EOF
