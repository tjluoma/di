#!/usr/bin/env zsh -f
# Purpose: Download the latest version of SwiftDefaultApps from <https://github.com/Lord-Kamina/SwiftDefaultApps>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-07-28

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO="$HOME/Library/PreferencePanes/SwiftDefaultApps.prefPane"

LATEST_URL=$(curl -sfLS --head --location "https://github.com/Lord-Kamina/SwiftDefaultApps/releases/latest" \
			| egrep -i '^Location: ' \
			| tail -1 \
			| awk '{print $2}' \
			| tr -d '\r')

LATEST_VERSION=$(echo "$LATEST_URL:t" | tr -dc '[0-9]\.')

URL=$(curl -sfLS "$LATEST_URL" | fgrep '/Lord-Kamina/SwiftDefaultApps/releases/download/' | sed 's#.*href="#https://github.com#g ; s#" .*##g')

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	(curl -sfLS "$LATEST_URL" \
	| sed '1,/<div class="markdown-body">/d; /<summary>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nonumbers -nolist -stdin; \
	echo "\nURL: $URL") | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

	# needs at least 10.12 to work
OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f2)

if [[ "$OS_VER" -lt "12" ]]
then
	echo "\n$NAME: SwiftDefaultApps.prefPane requires at least macOS 10.12. This is 10.$OS_VER.\n"
	exit 1
fi

## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$HOME/.Trash/"

	mv -fv "$FILENAME:r".* "$HOME/.Trash/"

	exit 0

fi

## unzip to a temporary directory
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

if [[ -w '/usr/local/scripts' ]]
then
	BINDIR='/usr/local/scripts'
elif [[ -w '/usr/local/bin' ]]
then
	BINDIR='/usr/local/bin'
elif [[ -w "$HOME/local/bin" ]]
then
	BINDIR="$HOME/local/bin"
else
	BINDIR=''
fi

if [[ "$BINDIR" != "" ]]
then

	MD_EXISTING=$(md5 -q "$BINDIR/swda")

	MD_NEW=$(md5 -q "$UNZIP_TO/swda")

	if [[ "$MD_EXISTING" == "$MD_NEW" ]]
	then

		mv -vf "$UNZIP_TO/swda" "$BINDIR/swda"

		EXIT="$?"

		if [ "$EXIT" = "0" ]
		then
			echo "$NAME: Successfully installed 'swda' to '$BINDIR'."

		else
			echo "$NAME: failed to install 'swda' to '$BINDIR' (\$EXIT = $EXIT)"

			exit 1
		fi

	else

		echo "$NAME: 'swda' is identical to the already-installed version."

	fi

fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
