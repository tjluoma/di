#!/bin/zsh -f
# Purpose: Download and install the latest version of Fluid 2
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Fluid.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

XML_FEED="https://fluidapp.com/appcast/fluid2.rss"

INFO=($(curl -sfL "$XML_FEED" \
		| tr '[:blank:]' '\012' \
		| egrep '^(sparkle:version="|sparkle:shortVersionString="|url="http.*\.zip")' \
		| head -3 \
		| sort ))

## Sort order will result in something like this:
# sparkle:shortVersionString="2.0"
# sparkle:version="1905"
# url="https://fluidapp.com/dist/Fluid_2.0.zip"
#
## NOTE: sparkle:version is changed even when sparkle:shortVersionString isn't

MAJOR_VERSION=$(echo "$INFO[1]" | tr -dc '[0-9]\.')

LATEST_VERSION=$(echo "$INFO[2]" | tr -dc '[0-9]\.')

URL=$(echo "$INFO[3]" | sed 's#url="##g; s#"##g')

if [ "$URL" = "" -o "$LATEST_VERSION" = "" -o "$MAJOR_VERSION" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED"
	echo "
	INFO: $INFO
	MAJOR_VERSION: $MAJOR_VERSION
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

fi

if (( $+commands[lynx] ))
then

	echo -n "$NAME: Release Notes for: "

	curl -sfL "$XML_FEED" \
	| sed '1,/<description>/d; /<\/description>/,$d ; s#&lt;#<#g' \
	| lynx -dump -nomargins -nonumbers -width=10000 -assume_charset=UTF-8 -pseudo_inlines -nolist -stdin

	echo "\nSource: XML_FEED <$XML_FEED>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${MAJOR_VERSION}-${LATEST_VERSION}.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$HOME/.Trash/\"."

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

exit 0
#
#EOF

