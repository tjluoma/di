#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-12-07

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# "https://github.com/obsidianmd/obsidian-releases/releases/download/v#{version}/Obsidian-#{version}.dmg"

## XML_FEED='https://github.com/obsidianmd/obsidian-releases/releases.atom'

INSTALL_TO='/Applications/Obsidian.app'

	# this doesn't change but it redirects to the latest URL
STATIC_RELEASE_URL='https://github.com/obsidianmd/obsidian-releases/releases/latest'

	# this is the actual URL for the latest release
	# such as 'https://github.com/obsidianmd/obsidian-releases/releases/tag/v1.0.2'
ACTUAL_RELEASE_URL=$(curl --head -sfLS "$STATIC_RELEASE_URL" | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

	# We can find the version number by looking at the end of the URL
	# and throwing away everything except numbers and periods
LATEST_VERSION=$(echo "$ACTUAL_RELEASE_URL:t" | tr -dc '[0-9]\.')

	# 2021-01-21 - DMG is now a universal binary 
DOWNLOAD_SUFFIX=$(curl -sfLS "$ACTUAL_RELEASE_URL" | tr '"' '\012' |  egrep -i '^/.*\.dmg$')

DOWNLOAD_PREFIX='https://github.com'

URL="${DOWNLOAD_PREFIX}${DOWNLOAD_SUFFIX}"


## Debugging info, if needed
# echo "
# ACTUAL_RELEASE_URL
# >$ACTUAL_RELEASE_URL<
#
# LATEST_VERSION
# >$LATEST_VERSION<
#
# URL
# >$URL<
# "

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

		# make sure that we can actually replace the version that is there
	if [[ ! -w "$INSTALL_TO" ]]
	then
			# if we can't write to the app, tell the user
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

			# and give up
		exit 2
	fi

else

		# if we get here, there is no version installed
	FIRST_INSTALL='yes'
fi

############################################################################################################

	# since there are different downloads for ARM and Intel, make sure we put $ARCH in filename
FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

	# this is the file we will use to store the release notes, if we have lynx installed
RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then
		# if we already have release notes, don't bother parsing them again, just show them
	cat "$RELEASE_NOTES_TXT"

else

	RELEASE_NOTES_URL=$(curl -sfLS "$STATIC_RELEASE_URL" \
		| tr '"' '\012' \
		| fgrep -i 'https://forum.obsidian.md/' \
		| egrep    '^https://forum.obsidian.md/' \
		| sort -u)

	echo "Release Notes: ${RELEASE_NOTES_URL}\n\nSource: ${ACTUAL_RELEASE_URL}\nVersion: ${LATEST_VERSION}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"
	
		## if we get here, we need to get the release notes but only if we have `lynx`
		## because I am not going to write an HTML parser because I am not a masochist
		## `lynx` isn't installed by default but can be installed via `brew`

	# if (( $+commands[lynx] ))
	# then
			## get the HTML of the ACTUAL_RELEASE_URL web page
			## use 'sed' to delete everything before and after the release notes
			## and then send whatever is left over to `lynx` to parse it
		# RELEASE_NOTES=$(curl -sfLS "${ACTUAL_RELEASE_URL}" \
		# 				| sed -e '1,/  <div class="commit-desc">/d' -e '/<summary>/,$d' \
		#				| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins)
		#
			## now, save the release notes and other info that might be useful and save it to the file we defined
		# echo "${RELEASE_NOTES}\n\nSource: ${ACTUAL_RELEASE_URL}\nVersion: ${LATEST_VERSION}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"
		#
	# fi
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

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	echo "$NAME: moving old installed version to '$HOME/.Trash'..."
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$HOME/.Trash'. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi
fi

############################################################################################################

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
