#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-04-12

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/BlockBlock Helper.app'

	# this doesn't change but it redirects to the latest URL
STATIC_RELEASE_URL='https://github.com/objective-see/BlockBlock/releases/latest'

	# this is the actual URL for the latest release
	# such as 'https://github.com/objective-see/BlockBlock/releases/tag/v1.0.2'
ACTUAL_RELEASE_URL=$(curl --head -sfLS "$STATIC_RELEASE_URL" | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

	# We can find the version number by looking at the end of the URL
	# and throwing away everything except numbers and periods
LATEST_VERSION=$(echo "$ACTUAL_RELEASE_URL:t" | tr -dc '[0-9]\.')

DOWNLOAD_SUFFIX=$(curl -sfLS "$ACTUAL_RELEASE_URL" | tr '"' '\012' |  egrep -i '^/.*/releases/.*\.zip$')

DOWNLOAD_PREFIX='https://github.com'

URL="${DOWNLOAD_PREFIX}${DOWNLOAD_SUFFIX}"

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
"

	exit 1
fi

	# is the app already installed? if so we need to compare version numbers
if [[ -e "$INSTALL_TO" ]]
then
		# if there's a version already, this isn't the first install
	FIRST_INSTALL='no'

		# this is the number to compare against the current version number
	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

		# zsh tool to compare version numbers
	autoload is-at-least

		# compare the numbers
	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

		# check the exit code
	VERSION_COMPARE="$?"

		# if exit code is zero, we have this version
	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

		# if we get here, there is a newer version
	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	# Normally we check for write access here, but the installer runs
	# via `sudo` and will be able to write to it, even if we cannot

else

		# if we get here, there is no version installed
	FIRST_INSTALL='yes'
fi

############################################################################################################

	# since there are different downloads for ARM and Intel, make sure we put $ARCH in filename
FILENAME="$HOME/Downloads/BlockBlock-${${LATEST_VERSION}// /}.zip"

	# this is the file we will use to store the release notes, if we have lynx installed
RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then
		# if we already have release notes, don't bother parsing them again, just show them
	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(curl -sfLS "$ACTUAL_RELEASE_URL" | sed '1,/<div class="markdown-body">/d; /<details/,$d' \
						| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins)

		echo "${RELEASE_NOTES}\n\n\nRelease Notes URL: ${RELEASE_NOTES_URL}\n\nSource: ${ACTUAL_RELEASE_URL}\nVersion: ${LATEST_VERSION}\nURL: ${URL}" \
		| tee "$RELEASE_NOTES_TXT"

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

############################################################################################################

TEMPDIR=$(mktemp -d "${TMPDIR-/tmp/}${NAME-$0:r}-XXXXXXXX")

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TEMPDIR/"

	mv -fv "$FILENAME:r".* "$TEMPDIR/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TEMPDIR}/${NAME}-XXXXXXXX")

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

INSTALLER="$UNZIP_TO/BlockBlock Installer.app/Contents/MacOS/BlockBlock Installer"

if [[ ! -e "$INSTALLER" ]]
then

	echo "$NAME: Failed to locate installer at '$INSTALLER'. Cannot continue." >>/dev/stderr
	exit 2

fi

sudo "${INSTALLER}" -install

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then

	echo "$NAME: Installation successful!"
	exit 0

else

	echo "$NAME: Installation failed (sudo \$EXIT = $EXIT)"
	exit 1

fi

#EOF
