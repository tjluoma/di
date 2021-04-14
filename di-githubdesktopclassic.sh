#!/usr/bin/env zsh -f
# Purpose: download and install GitHub’s Mac app (now referred to as “Classic” since they have a new Electron-based version now.)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-09-30, updated and renamed 2018-08-26

NAME="$0:t:r"

INSTALL_TO='/Applications/GitHub Desktop Classic.app'

# HOMEPAGE="https://blog.github.com/2015-08-12-github-desktop-is-now-available/"

DOWNLOAD_PAGE="https://github-central.s3.amazonaws.com/mac/GitHub%20Desktop%20224.zip"

SUMMARY="The older, non-Electron, version of GitHub Desktop (sometimes known as “GitHub for Mac”)."

# Note: It's technically called “GitHub Desktop.app” but since the new version also uses that name
# I've taken the liberty of renaming this to what GitHub seems to call it now.
# See https://blog.github.com/2017-09-19-announcing-github-desktop-1-0/ for announcement of its replacement

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

URL="https://github-central.s3.amazonaws.com/mac/GitHub%20Desktop%20224.zip"

# Bytes = 29721791
# MD5 = 01db3451668b8790bf6b74b13e4baec7
# shasum -a 256 or gsha256sum = 4933303a2d8f2545422d395b5ad8d5cb5a16aabd746304e139260d15578bd5cb

LATEST_VERSION="224"

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

FILENAME="$HOME/Downloads/GitHubDesktopClassic-$LATEST_VERSION.zip"

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
	# Note that we have to specify the name since we're renaming it on install.
	# See note at top of document.
mv -vn "$UNZIP_TO/GitHub Desktop.app" "$INSTALL_TO"

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

# 2018-08-26 - We don't really need to calculate any of this anymore, since the app is EOL. But here's how it worked:

# OS_VER=`SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion || echo '10.11'`
# 	# If you are Up-To-Date, you get an empty document with a 204 response code
# RESPONSE=`curl --head -sfL "https://central.github.com/api/mac/latest?version=${INSTALLED_VERSION}&os_version=${OS_VER}" | awk -F' ' '/^HTTP/{print $2}'`
#
# if [[ "$RESPONSE" == "204" ]]
# then
# 	echo "$NAME: Up-To-Date (Version $INSTALLED_VERSION)"
# 	exit 0
# fi
#
# INFO=($(curl -sfL "https://central.github.com/api/mac/latest?version=${INSTALLED_VERSION}&os_version=${OS_VER}" \
# 		| tr ',' '\012' \
# 		| egrep '"version"|"url"' \
# 		| head -2 \
# 		| awk -F'"' '//{print $4}'))
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

#EOF
