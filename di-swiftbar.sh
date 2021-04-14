#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of https://github.com/swiftbar/SwiftBar/
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-11-30

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# where do you want the app to be installed?
INSTALL_TO='/Applications/SwiftBar.app'

	# this doesn't change but it redirects to the latest URL
STATIC_RELEASE_URL='https://github.com/swiftbar/SwiftBar/releases/latest'

	# this is the actual URL for the latest release
	# such as 'https://github.com/swiftbar/SwiftBar/releases/tag/v1.0.2'
ACTUAL_RELEASE_URL=$(curl --head -sfLS "$STATIC_RELEASE_URL" | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

	# We can find the version number by looking at the end of the URL
	# and throwing away everything except numbers and periods
LATEST_VERSION=$(echo "$ACTUAL_RELEASE_URL:t" | tr -dc '[0-9]\.')

	# parse the ACTUAL_RELEASE_URL page to look for a link which has the path
	# /swiftbar/SwiftBar/releases/download/
	# and ends with '.zip'
	# which is the URL we need to download the latest version of the compiled app
	# not source code
URL=$(curl -sfLS "${ACTUAL_RELEASE_URL}" \
		| egrep '.*a href=.*/swiftbar/SwiftBar/releases/download/.*\.zip' \
		| sed -e 's#" .*##g' -e 's#.*<a href="#https://github.com#g')

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

	# this is where the new version will be downloaded to
FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.zip"

	# this is the file we will use to store the release notes, if we have lynx installed
RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then
		# if we already have release notes, don't bother parsing them again, just show them
	cat "$RELEASE_NOTES_TXT"

else

		# if we get here, we need to get the release notes but only if we have `lynx`
		# because I am not going to write an HTML parser because I am not a masochist
		# `lynx` isn't installed by default but can be installed via `brew`

	if (( $+commands[lynx] ))
	then
			# get the HTML of the ACTUAL_RELEASE_URL web page
			# use 'sed' to delete everything before and after the release notes
			# and then send whatever is left over to `lynx` to parse it
		RELEASE_NOTES=$(curl -sfLS "${ACTUAL_RELEASE_URL}" \
						| sed -e '1,/  <div class="markdown-body">/d' -e '/<summary>/,$d' \
						| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins)

			# now, save the release notes and other info that might be useful and save it to the file we defined
		echo "${RELEASE_NOTES}\n\nSource: ${ACTUAL_RELEASE_URL}\nVersion: ${LATEST_VERSION}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"

	fi
fi

	# tell the user what we are trying to download and from where
echo "$NAME: Downloading '$URL' to '$FILENAME':"

	## Here is where we actually download the file
curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	# this part isn't really all that necessary but I've been doing it anyway
	# once the file is downloaded, I save the shasum of it for later reference
	# this isn't really a security feature because we don't have anything to compare
	# it to, but we can tell later if it's been corrupted

	# is the sha256 already in the text file?
egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

	# if yes, don't bother adding it again
	# otherwise, do add it
if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

	# we need a temporary directory where we can unzip the file
	# so we create one
UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME-$0:r}-XXXXXXXX")

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
		# tell the user that we checked the validity
	echo "$NAME: '$FILENAME' is a valid zip file."

else
		# if it is NOT valid, corrupted, etc then move it
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)" >>/dev/stderr

		# move it to the UNZIP_TO so it's not deleted
		# in case we want to try to diagnose the problem
	mv -fv "$FILENAME" "$UNZIP_TO/"

		# move the release notes too
	mv -fv "$FILENAME:r".* "$UNZIP_TO/"

		# we've reported an error so we should exit appropriately
	exit 2

fi

	# if we get here, the zip is valid, so let's open it
echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

	# here's the actual unzipping
	# which is done with 'ditto' on the very unlikely chance
	# that 'unzip' can't deal with resource forks or something
ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

	# check to see if 'ditto' worked
EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
		# tell the user we succeeded
	echo "$NAME: Unzip successful to '$UNZIP_TO'"
else
		# tell the user we failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

	# if there's an already-installed version, let's quit it (if it's running)
	# and move it to the trash.
	# We'll restart it later it if it was running

if [[ -e "$INSTALL_TO" ]]
then
		# is it running? if so, save a variable to tell us to relaunch it
		# and then quit the app
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# tell the user we are moving the old one
	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$UNZIP_TO/'."

		# move the installed app to the trash
		# rename it to include the version number
		# in case we want to reinstall it again later for some reason
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.$$.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
			# tell the user we failed to move the existing version
		echo "$NAME: failed to move existing '$INSTALL_TO' to '$HOME/.Trash/'." >>/dev/stderr

		exit 1
	fi
fi

	# tell the user we are about to move the file out of the temp folder to the actual
echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# this is where we actually move the new version to the proper location
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then
		# did the move succeed? If so, tell the user
	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
		# did the move fail? If so, tell the user?
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'." >>/dev/stderr

	exit 1
fi

	# if we previously quit the app because it was running and needed to be replaced
	# then we should launch the new version
[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

	# We did it!
exit 0

#EOF
