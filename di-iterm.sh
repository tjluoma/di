#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of iTerm
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19, updated: 2018-08-02 ; 2019-08-01 added support for older versions of macOS

NAME="$0:t:r"

INSTALL_TO="/Applications/iTerm.app"

HOMEPAGE="https://iterm2.com/"

DOWNLOAD_PAGE="https://iterm2.com/downloads.html"

SUMMARY="iTerm2 brings the terminal into the modern age with features you never knew you always wanted."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

PPID_NAME=$(/bin/ps -p $PPID | fgrep '/sbin/launchd' | awk '{print $NF}')

if [ "$PPID_NAME" = "/sbin/launchd" ]
then
		# this was launched via launchd. We don't want to use 'exit 1' in launchd because it might keep it from running again
	function die { exit 0 }
else
	function die { exit 1 }
fi


	# LSMinimumSystemVersion is not set (as of 3.3.0) so we rely on information from
	# https://www.iterm2.com/downloads.html

OS_VER=$(sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -ge "12" ]
then

		# if you want to install beta releases
		# create a file (empty, if you like) using this file name/path:
	PREFERS_BETAS_FILE="$HOME/.config/di/prefers/iterm-prefer-betas.txt"

	if [[ -e "$PREFERS_BETAS_FILE" ]]
	then
			## this is for betas
		HEAD_OR_TAIL='tail'
		NAME="$NAME (beta releases)"
		XML_FEED="https://iterm2.com/appcasts/nightly.xml"

		URL=$(curl -sfLS --head 'https://iterm2.com/nightly/latest' | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

		LATEST_VERSION=$(echo "$URL:t:r" | sed -e 's#iTerm2-##g' -e 's#_#.#g')

		RELEASE_NOTES_URL='https://iterm2.com/appcasts/nightly_changes.txt'

	else
			## This is for official, non-beta versions
		HEAD_OR_TAIL='tail'
		XML_FEED="https://iterm2.com/appcasts/final.xml"

			# 'CFBundleVersion' and 'CFBundleShortVersionString' are identical in app, but only one is in XML_FEED
		INFO=($(curl -sfL "$XML_FEED" \
				| tr ' ' '\012' \
				| egrep '^(url|sparkle:version)=' \
				| ${HEAD_OR_TAIL} -2 \
				| sort \
				| awk -F'"' '//{print $2}'))

		LATEST_VERSION="$INFO[1]"

		URL="$INFO[2]"

		# This always seems to be a plain-text file, but the filename itself changes
		RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
			| sed "1,/<title>Version $LATEST_VERSION<\/title>/d; /<\/sparkle:releaseNotesLink>/,\$d ; s#<sparkle:releaseNotesLink>##g" \
			| awk -F' ' '/https/{print $1}')

			# If any of these are blank, we should not continue
		if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
		then
			echo "$NAME: Error: bad data received:
			INFO: $INFO
			LATEST_VERSION: $LATEST_VERSION
			URL: $URL
			"

			die
		fi
	fi

elif [ "$OS_VER" -ge "10" ]
then
		# if this is macOS 10.10 or later

	URL='https://iterm2.com/downloads/stable/iTerm2-3_1_7.zip'
	LATEST_VERSION='3.1.7'
	RELEASE_NOTES_URL=''

elif [ "$OS_VER" -ge "8" ]
then
		# if this is macOS 10.8 or later
	URL=' https://iterm2.com/downloads/stable/iTerm2-3_0_15.zip'
	LATEST_VERSION='3.1.5'
	RELEASE_NOTES_URL=''

else

	echo "$NAME: Not sure what version is compatible with mac OS 10.$OS_VER."
	echo '	See <https://www.iterm2.com/downloads.html> for available versions.'
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

FILENAME="$HOME/Downloads/${INSTALL_TO:t:r}-${LATEST_VERSION}.zip"

## Release Notes - start
if [[ "$RELEASE_NOTES_URL" != '' ]]
then
	( echo -n "$NAME: Release Notes for " ;
	  curl -sfL "$RELEASE_NOTES_URL" ;
	  echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"
fi
## Release Notes - end

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

	die
fi

if [[ -e "$INSTALL_TO" ]]
then

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		die
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

	die
fi

exit 0
EOF
