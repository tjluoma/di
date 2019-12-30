#!/usr/bin/env zsh -f
# Purpose: Download the latest version of Soundnode from <http://www.soundnodeapp.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-06-02 ; major update 2019-11-14

NAME="$0:t:r"

## DO NOT USE THIS
# DOWNLOAD_PAGE="http://www.soundnodeapp.com/downloads/mac/Soundnode.zip"
#
## USE THIS
# https://github.com/Soundnode/soundnode-app/releases/latest

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Soundnode.app'
else
	INSTALL_TO='/Applications/Soundnode.app'
fi

HOMEPAGE="https://github.com/Soundnode/soundnode-app"

DOWNLOAD_PAGE='https://github.com/Soundnode/soundnode-app/releases/latest'

SUMMARY="An opensource SoundCloud app for desktop."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	## Get URL of latest release which will include version number
LATEST_RELEASE_URL=$(curl --head -sfLS "https://github.com/Soundnode/soundnode-app/releases/latest" | awk -F' |\r' '/^Location:/{print $2}')

LATEST_VERSION=$(echo "$LATEST_RELEASE_URL:t")

DOWNLOAD_SUFFIX=$(curl -sfLS "$LATEST_RELEASE_URL" \
				| tr '"' '\012' \
				| egrep -i '^/Soundnode/soundnode-app/releases/download/.*\Soundnode-darwin-x64.tar.xz')

URL=$(echo "https://github.com${DOWNLOAD_SUFFIX}")

	# n.b. CFBundleShortVersionString and CFBundleVersion are identical

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Here’s the download section
#

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.tar.xz"

if (( $+commands[lynx] ))
then

		## 2019-11-14 -- note the '&middot;' replacement
		## without it, the 'sed' _after_ lynx complains about an 'illegal byte sequence'
		##
		## Previously work-around was to prefix the last 'sed' call with
		## 		LC_ALL=C
		##
		## Also note:
		##  	LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8  == 'sed: RE error: illegal byte sequence'
		## 		LC_ALL=en_US_UTF-8 = 'middot' replaced with '∑'
		##
		## Long story short: just replace '&middot;'

	RELEASE_NOTES=$(curl -sfLS "$LATEST_RELEASE_URL" \
		| sed -e '1,/release-header/d; /release-body/,$d' -e 's#&middot;#•#g' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| sed 's#file:///#https://github.com/#g')

	echo "Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n\n${RELEASE_NOTES}\n\nSource: ${LATEST_RELEASE_URL}\nURL: ${URL}" \
	| tee "$FILENAME:r:r.txt"

	# Note the '"$FILENAME:r:r.txt"' has two :r because the filename is '.tar.xz' not '.txz'

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r:r.txt"

# Note: while macOS does not have a separate `xz` command, the `tar` command apparently understands how to deal
# with a .tar.xz file, going back at least to 10.11

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unpacking '$FILENAME' to '$UNZIP_TO':"

tar -x -C "$UNZIP_TO" -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" != "0" ]
then
	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)"
	exit 1
fi

	# This is the path to the actual app in the temporary directory we just created
TEMP_APP=$(find "$UNZIP_TO" -type d -iname 'Soundnode.app' -maxdepth 2 -print 2>/dev/null)

if [[ "$TEMP_APP" == "" ]]
then
	echo "$NAME: Failed to find 'Soundnode.app' in '$UNZIP_TO'." >>/dev/stderr
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"
		exit 1
	fi
fi

	## this is where we install the temp file to the place where it belongs
mv -vn "$TEMP_APP" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: successfully installed version '$LATEST_VERSION' to '$INSTALL_TO'."

else
	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

exit 0
#EOF
