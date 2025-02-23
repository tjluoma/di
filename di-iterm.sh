#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of iTerm
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Original:	2016-01-19
# Verified:	2025-02-22

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/iTerm.app"

NAME="$0:t:r"

HOMEPAGE="https://iterm2.com/"

DOWNLOAD_PAGE="https://iterm2.com/downloads.html"

SUMMARY="iTerm2 brings the terminal into the modern age with features you never knew you always wanted."

	## For Nightly Builds
# XML_FEED='https://iterm2.com/appcasts/nightly_new.xml'

	## For Beta Builds
# XML_FEED='https://iterm2.com/appcasts/testing_new.xml'

	## For regular Builds
XML_FEED='https://iterm2.com/appcasts/final_modern.xml'


## Ok, so when I can't remember what this does, here are some bread crumbs :
# Take the XML_FEED and replace all of the EOL and tabs with spaces (tr)
# look for '<item>' and put a newline before it (sed)
# look for '</item>' and put a newline after it (sed)
# fgrep for '<item>'
# tail -1 to get take the last one (the nightly and betas might only have 1 item in the feed
# sed   - look for >< and put a newline between them
#	   - look for a space and convert it to a newline
#	   - look for  <sparkle:releaseNotesLink>   and make it	sparkle:releaseNotesLink="
#	   - look for  </sparkle:releaseNotesLink> and make it a " instead
# egrep just the lines:
#	   ^sparkle:releaseNotesLink=
#	   ^sparkle:version=
#	   ^url=
# sort to make sure those 3 lines are always in the same order even if the XML_FEED changes
# awk to get just the stuff between the " marks

# 2019-08-01 - I'm not sure why I had to break that up into two separate calls
#				but I was getting an error when I tried to make it as one long one.

CURL=$(curl -sfLS "$XML_FEED" | tr -s '\t|\012' ' ' | sed -e 's#<item>#\
<item>#g ; s#</item>#</item>\
#g' -e 's#> #>#g' -e 's/ </</g')

INFO=($(echo "$CURL" | fgrep '<item>' | tail -1 | sed -e 's#><#>\
<#g' -e 's# #\
#g' -e 's#<sparkle:releaseNotesLink>#sparkle:releaseNotesLink="#g' -e 's#</sparkle:releaseNotesLink>#"#g' \
| egrep '^(sparkle:releaseNotesLink|sparkle:version|url)=' \
| sort \
| awk -F'"' '//{print $2}'))

RELEASE_NOTES_URL="$INFO[1]"
LATEST_VERSION="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL

	PREFERS: $PREFERS
	XML_FEED: $XML_FEED \n"

	exit 1
fi


if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

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

	if [[ ! -e "$FILENAME:r.txt" ]]
	then
		( echo -n "$NAME: Release Notes for iTerm version $LATEST_VERSION ${PREFERS}\n\n" ;
		  curl -sfL "$RELEASE_NOTES_URL" ;
		  echo "\nSource: <$RELEASE_NOTES_URL>\nHome: ${HOMEPAGE} \nDownloads: ${DOWNLOAD_PAGE} \nSummary: ${SUMMARY} \nURL: ${URL} \nXML_FEED: ${XML_FEED}" ) \
		  | tee "$FILENAME:r.txt"
	fi

fi
	## Release Notes - end

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	# save the sha256 checksum to a file
egrep -q '^Local sha256:$' "$FILENAME:r.txt"

EXIT="$?"

if [[ "$EXIT" == "1" ]]
then

	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"

fi

	# make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is NOT a valid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$HOME/.Trash/"

	mv -fv "$FILENAME:r".* "$HOME/.Trash/"

	exit 1

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

exit 0
EOF
