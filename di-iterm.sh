#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of iTerm
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Original Date:	2016-01-19
# Updated As Of:	2019-08-01 - added support for older versions of macOS and improved support for nightly / beta builds

## NOTE:
## By default, this script assumes that you want to check for 'Stable' releases of iTerm.app.
## However, there are two other options: "Nightly" builds and "Test" (aka "Beta") builds.
##
## A nightly build is made at midnight Pacific time on days where a change was committed.
## The change log may be seen on Github. Nightly builds sometimes have serious bugs.
##
## Test/Beta releases update many times a year and are occasionally unstable.
##
## If you want this script to download and install "Nightly" builds, create a file
## at "$HOME/.iterm-prefer-nightly.txt"
##
## If you want this script to download and install "Test/Beta" builds, create a file
## at "$HOME/.iterm-prefer-betas.txt"
##
## (If both files exist, it will be assumed that the user wants 'nightly' builds.)
##
## The contents of the file are ignored. The file only has to exist, so
##
##		touch "$HOME/.iterm-prefer-betas.txt"
##
## would be enough to indicate your preference.



NAME="$0:t:r"

INSTALL_TO="/Applications/iTerm.app"

HOMEPAGE="https://iterm2.com/"

DOWNLOAD_PAGE="https://iterm2.com/downloads.html"

SUMMARY="iTerm2 brings the terminal into the modern age with features you never knew you always wanted."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

PPID_NAME=$(/bin/ps -p $PPID | fgrep '/sbin/launchd' | awk '{print $NF}')

if [ "$PPID_NAME" = "/sbin/launchd" ]
then
		# if this script was launched via launchd, we don't want to use 'exit 1'
		# because that might prevent it from running again automatically
	function die { exit 0 }
else
	function die { exit 1 }
fi

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -ge "12" ]
then

	if [ -e "$HOME/.config/di/prefers/iterm-prefer-nightly.txt" -o -e "$HOME/.iterm-prefer-nightly.txt" ]
	then
		XML_FEED='https://iterm2.com/appcasts/nightly_new.xml'
		PREFERS='[Nightly]'

	elif [ -e "$HOME/.config/di/prefers/iterm-prefer-betas.txt"  -o -e "$HOME/.iterm-prefer-betas.txt" ]
	then
		XML_FEED='https://iterm2.com/appcasts/testing_new.xml'
		PREFERS='[Beta]'

	else
			# Stable releases update rarely but have no serious bugs.
		XML_FEED='https://iterm2.com/appcasts/final_new.xml'
		#XML_FEED='https://iterm2.com/appcasts/final.xml'
		PREFERS='[Stable]'
	fi

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

elif [ "$OS_VER" -ge "10" ]
then
		# if this is macOS 10.10 or later

	# URL='https://iterm2.com/downloads/stable/iTerm2-3_1_7.zip'
	# LATEST_VERSION='3.1.7'
	# RELEASE_NOTES_URL='https://iterm2.com/appcasts/3.1.7.txt'

	LATEST_VERSION='3.1.6beta4'
	URL='https://iterm2.com/misc/iTerm2-3.1.7-notmux.zip'
	RELEASE_NOTES_URL='https://groups.google.com/forum/m/#!topic/iterm2-discuss/57k_AuLdQa4'

elif [ "$OS_VER" -ge "8" ]
then
		# if this is macOS 10.8 or later
	URL='https://iterm2.com/downloads/stable/iTerm2-3_0_15.zip'
	LATEST_VERSION='3.1.5'
	RELEASE_NOTES_URL='https://iterm2.com/appcasts/30.txt'

else
		# this is for anything else, so… 10.7 and earlier?
	URL='https://iterm2.com/downloads/stable/iTerm2-2_1_4.zip'
	LATEST_VERSION='2.1.4'
	RELEASE_NOTES_URL='https://iterm2.com/appcasts/2x.txt'
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

	die

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

	die
fi

if [[ -e "$INSTALL_TO" ]]
then

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then
		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		die
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

	die
fi

exit 0
EOF
