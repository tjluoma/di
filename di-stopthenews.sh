#!/usr/bin/env zsh -f
# Purpose: Get the latest version of Stop The News
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-07

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/StopTheNews.app'

URL=$(curl -sfLS "https://github.com/lapcat/StopTheNews/releases/latest" \
		| egrep '<a href="/lapcat/StopTheNews/releases/download/.*\.zip' \
		| sed 's#.*/lapcat/#https://github.com/lapcat/#g ; s#.zip".*#.zip#g')

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#StopTheNews##g')

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

	(echo "StopTheNews version $LATEST_VERSION:\n$URL\n\n" ;
		curl -sfLS "https://github.com/lapcat/StopTheNews/releases.atom"\
		|awk '/<entry>/{i++}i==1' \
		| sed -e '1,/<title>/d; /<author>/,$d' -e 's#<content type="html">##g' -e 's#</content>##g' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nonumbers -nolist -stdin \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nonumbers -nolist -stdin ) \
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
#EOF
