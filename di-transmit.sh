#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Transmit 5 from <https://www.panic.com/transmit/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-19

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Transmit.app"

NAME="$0:t:r"

HOMEPAGE="https://panic.com/transmit/"

DOWNLOAD_PAGE="https://download.panic.com/transmit/?C=M;O=D"

SUMMARY="The gold standard of macOS file transfer apps just drove into the future. Upload, download, and manage files on tons of servers with an easy, familiar, and powerful UI. It’s quite good."


# if [[ -e "$INSTALL_TO" ]]
# then
#
# 	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)
# 	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)
#
# else
# 		# if it's not installed, fake a slightly older version
# 	INSTALLED_VERSION='5.6.1'
# 	INSTALLED_BUILD='133740'
# fi
#
# MAC_TYPE=$(sysctl hw.model | awk -F' ' '/^hw.model/{print $NF}')
#
# DARWIN_VERSION=$(uname -r)
#
# CFNETWORK_VER=$(defaults read "/System/Library/Frameworks/CFNetwork.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString)
#
# OS_VER=$(sw_vers -productVersion)
#
# 	# the feed reports itself as 'http://www.panic.com/updates/transmit/transmit-en.xml' but that URL is 404
# # XML_FEED="https://www.panic.com/updates/update.php?osVersion=${OS_VER}&cputype=7&cpu64bit=1&cpusubtype=8&model=${MAC_TYPE}&ncpu=4&lang=en-US&appName=Transmit&appVersion=${INSTALLED_BUILD}&cpuFreqMHz=1600&ramMB=16384"
#
# XML_FEED='https://panic.com/updates/soapbox.php?app=Transmit&appver=${INSTALLED_VERSION}&appbuild=${INSTALLED_BUILD}&os=${OS_VER}&model=${MAC_TYPE}&mas=0&sync=1'
#
# TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.xml"
#
# curl \
# 	-H "Accept: application/rss+xml,*/*;q=0.1" \
# 	-H "Accept-Language: en-us" \
# 	-H "User-Agent: Transmit/${INSTALLED_VERSION} Sparkle/1.14.0" \
# 	-sfLS "$XML_FEED" >| "$TEMPFILE"
#
#
# MINIMUM_VERSION=$(fgrep '<sparkle:minimumSystemVersion>' "$TEMPFILE" \
# 		| head -1 \
# 		| sed 's#.*<sparkle:minimumSystemVersion>##g ; s#</sparkle:minimumSystemVersion>##g')
#
# autoload is-at-least
#
# is-at-least "$MINIMUM_VERSION" "$OS_VER"
#
# VER_TEST="$?"
#
# if [[ "$VER_TEST" == "1" ]]
# then
# 	echo "$NAME: Transmit requires at least '$MINIMUM_VERSION' of Mac OS. You have '$OS_VER'. Cannot continue."
# 	exit 1
# fi
#
# IFS=$'\n' INFO=($(egrep 'sparkle:version|sparkle:shortVersionString|url=' "$TEMPFILE" \
# 		| head -3 \
# 		| sort \
# 		| sed 's#"$##g ; s#.*"##g'))
#
# 	# "Sparkle" will always come before "url" because of "sort"
# LATEST_VERSION="$INFO[1]"
# LATEST_BUILD="$INFO[2]"
# URL="$INFO[3]"
#
# 	# Replace a space in the URL with '%20'
# 	# WHO PUTS SPACES IN URLs?!?!
# URL=$(echo "$URL" | sed 's# #%20#g' )
#
# 	# If any of these are blank, we cannot continue
# if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
# then
# 	echo "$NAME: Error: bad data received:
# 	INFO: $INFO
#
# 	LATEST_VERSION: $LATEST_VERSION
# 	LATEST_BUILD: $LATEST_BUILD
# 	URL: $URL
# 	"
#
# 	exit 1
# fi
#
# if [[ -e "$INSTALL_TO" ]]
# then
#
# 	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)
#
# 	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)
#
# 	autoload is-at-least
#
# 	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"
#
# 	VERSION_COMPARE="$?"
#
# 	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"
#
# 	BUILD_COMPARE="$?"
#
# 	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
# 	then
# 		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
# 		exit 0
# 	fi
#
# 	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"
#
# 	FIRST_INSTALL='no'
#
# else
#
# 	FIRST_INSTALL='yes'
# fi

	# This also depends on the format of their download URLs not changing
	# as of 2018-07-19, all of these URL formats seem to work but redirect:
	#
	# "https://www.panic.com/transmit/d/Transmit%20${LATEST_VERSION}.zip"
	# 302 ->
	# "Location: https://panic.com/download/transmit/Transmit%20${LATEST_VERSION}.zip"
	# 302 ->
	# "Location: https://download.panic.com/transmit/Transmit%20${LATEST_VERSION}.zip"

# [[ "$URL" == "" ]] && echo "$NAME: '$URL' was empty. Using backup URL" &&  URL="https://download.panic.com/transmit/Transmit%20${LATEST_VERSION}.zip"


LATEST_BUILD=''

LATEST_VERSION=$(curl -sfLS "https://download.panic.com/transmit/?C=M;O=D" \
					| tr '"' '\012' \
					| egrep -i '^https://download.panic.com/.*/Transmit.*\.zip' \
					| egrep -vi 'Transmit%205%20Automator%20actions|Transmit%20Disk%20' \
					| sed 's#.*Transmit%20##g; s#\.zip##g' \
					| sort --sort=human-numeric \
					| tail -1)

URL="https://download.panic.com/transmit/Transmit%20${LATEST_VERSION}.zip"

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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi


# 	# So let's quickly test to make sure it's valid
# HTTP_CODE=$(curl --silent --location --head "$URL" \
# 			| awk -F' ' '/^HTTP/{print $2}' \
# 			| tail -1)
#
# if [[ "$HTTP_CODE" != "200" ]]
# then
# 		# Download URL does NOT exist
# 	echo "$NAME: '$URL' not valid: HTTP_CODE = $HTTP_CODE"
# 	exit 1
# fi

if [[ "$LATEST_BUILD" == "" ]]
then
	FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"
else
	FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.zip"
fi


# if (( $+commands[lynx] ))
# then
#
# 	RELEASE_NOTES_URL=$(fgrep '<sparkle:releaseNotesLink>' "$TEMPFILE" \
# 		| head -1 \
# 		| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')
#
# 	(echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
# 	 lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "${RELEASE_NOTES_URL}" ;
# 	 echo "\nSource: <$RELEASE_NOTES_URL>") | tee "$FILENAME:r.txt"
#
# fi

# echo "$NAME: Downloading '$URL' to '$FILENAME':" | cat -v

# curl -A "Transmit/${INSTALLED_VERSION} Sparkle/1.14.0" --continue-at - --fail --location --output "$FILENAME" "$URL"





########################################################################################################################

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL="https://library.panic.com/releasenotes/transmit5/$LATEST_VERSION/"

		RELEASE_NOTES=$(lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL")

		echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nVersion: ${LATEST_VERSION} / ${LATEST_BUILD}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"

	fi

fi



echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#
#EOF
