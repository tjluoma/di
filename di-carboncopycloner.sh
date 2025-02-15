#!/usr/bin/env zsh -f
# Purpose: Download/Install/Upgrade Carbon Copy Cloner version 3, 4, or 5, depending on OS and what's installed.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

# @todo - use wget for release notes to get working links


NAME="$0:t:r"

INSTALL_TO="/Applications/Carbon Copy Cloner.app"

HOMEPAGE="https://bombich.com"

DOWNLOAD_PAGE="https://bombich.com/download"

SUMMARY="The first bootable backup solution for the Mac is better than ever."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

autoload is-at-least

if [[ -e "$INSTALL_TO" ]]
then
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | sed 's#\\u0192##g')

	USE_VERSION=$(echo "$INSTALLED_VERSION" | cut -d '.' -f 1)

else
	INSTALLED_VERSION='0'
fi

	## NOTE: If nothing is installed, we need to pretend we have at least version 8?
	## The actual latest version is 7 but we need 8 here. I don't know why. There's probably a reason
INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '8.0.0')

	## NOTE: If nothing is installed, we need to pretend we have at least version 8000
INSTALLED_BUILD=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '8000')

VERSION=($(sw_vers -productVersion | tr '.' ' '))

OS_MAJOR="$VERSION[1]"

OS_MINOR="$VERSION[2]"

OS_BUGFIX="$VERSION[3]"

XML_FEED="https://update.bombich.com/software/updates/ccc.php?os_major=${OS_MAJOR}&os_minor=${OS_MINOR}&os_bugfix=${OS_BUGFIX}&ccc=${INSTALLED_BUILD}&beta=0&locale=en"

INFO=($(curl -sfL "$XML_FEED" \
		| egrep '"(version|build|downloadURL)":' \
		| head -3 \
		| tr -d ',|"' \
		| sort ))

# sort gives us: build vs downloadURL vs version with each field being followed by the corresponding value
LATEST_BUILD="$INFO[2]"
URL="$INFO[4]"
LATEST_VERSION="$INFO[6]"

# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$LATEST_BUILD" = "" ]
then
	echo "$NAME: Error: bad data received from ${XML_FEED}\n\tINFO: $INFO\n\tURL: $URL\n\tLATEST_VERSION: $LATEST_VERSION\n\tLATEST_BUILD: $LATEST_BUILD\n"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"
fi

FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfLS "$XML_FEED" | awk -F'"' '/releaseNotes/{print $4}' | ${HEAD_OR_TAIL} -1)

	( curl -H "Accept-Encoding: gzip,deflate" -sfLS "$RELEASE_NOTES_URL" \
		| gunzip \
		| sed '1,/<details open id="primary">/d; /<details>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

		# save the HTML too
	curl -sfLS "$RELEASE_NOTES_URL" > "$FILENAME:r.html"

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -n "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

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
