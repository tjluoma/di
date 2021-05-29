#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Lunar
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-05-29

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Lunar.app'

HOMEPAGE='https://lunar.fyi'

XML_FEED='https://lunar.fyi/appcast.xml'

INFO=$(curl -sfLS "$XML_FEED" \
		| sed 's#^ *##g' \
		| tr -d '\012' \
		| sed 	-e 's#.*<item>#<item>#g' \
				-e 's#</item>.*##g' \
		| sed 's#<#\
<#g' \
		| fgrep -iv 'sparkle:delta' \
		| fgrep -iv 'signature>' \
		| sed 's#" #"\
#g')

URL=$(echo "$INFO" | awk -F'"' '/^url/{print $2}')

LATEST_BUILD=$(echo "$INFO" | awk -F'"' '/^sparkle:version/{print $2}')

LATEST_VERSION=$(echo "$INFO" | awk -F'"' '/^sparkle:shortVersionString/{print $2}')

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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

if [[ "$LATEST_VERSION" == "$LATEST_BUILD" ]]
then

	FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.zip"

else

	FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.zip"

fi

FINAL_PKG_NAME="$FILENAME:r.pkg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(echo "$INFO" \
						| sed '1,/CDATA/d; /\]\]/,$d' \
						| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins)

		echo "${RELEASE_NOTES}\n\nSource: ${XML_FEED}\nVersion: ${LATEST_VERSION} / ${LATEST_BUILD}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

###### First we need to unzip and then install a pkg

UNZIP_DIR=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_DIR':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_DIR"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	PKG=$(find ${UNZIP_DIR}/ -iname '*.pkg' -print)
	echo "$NAME: Unzip successful to \$UNZIP_DIR: $UNZIP_DIR.\n\$PKG is '$PKG'."
else
	echo "$NAME failed (ditto -xk '$FILENAME' '$UNZIP_DIR')" >>/dev/stderr
	exit 2
fi

########## We now have a pkg in a variable named '$PKG'
########## Which should be renamed to '$FINAL_PKG_NAME'

if [[ -e "$FINAL_PKG_NAME" ]]
then
	echo "$NAME: 'FINAL_PKG_NAME' already exists at '$FINAL_PKG_NAME'." >>/dev/stderr
	exit 2
fi

####################################################################################################

mv -vn "$PKG" "$FINAL_PKG_NAME"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then

	echo "$NAME: Failed to rename '$PKG' to '$FINAL_PKG_NAME' (\$EXIT = $EXIT)" >>/dev/stderr

	exit 2
fi

FILENAME="$FINAL_PKG_NAME"

####################################################################################################

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

####################################################################################################

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME"

else
		# fall back to either `sudo installer` or macOS's installer app
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1 \
	|| open -b com.apple.installer "$FILENAME"

fi

####################################################################################################

exit 0
#
#EOF
