#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Hazel
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-23 (2016-04-22 - changed from .dmg to .zip)

NAME="$0:t:r"

HOMEPAGE="https://www.noodlesoft.com"

DOWNLOAD_PAGE="https://www.noodlesoft.com/Products/Hazel/download"

OLDER='https://www.noodlesoft.com/old-versions/'

SUMMARY="Hazel watches whatever folders you tell it to, automatically organizing your files according to the rules you create. Have Hazel move files around based on name, date, type, what site it came from and much more. Automatically sort your movies or file your bills. Keep your files off the desktop and put them where they belong."

	## If you want to install Hazel for all users, replace 'INSTALL_TO=' with this line
	# INSTALL_TO='/Library/PreferencePanes/Hazel.prefPane'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion)

[[ "$OS_VER" == "10.16" ]] && echo "$NAME: Not ready for Big Sur yet" && exit 0

if [ -e "/Library/PreferencePanes/Hazel.prefPane" -a -e "$HOME/Library/PreferencePanes/Hazel.prefPane" ]
then

	echo "$NAME: Hazel.prefPane is installed at _BOTH_ '/Library/PreferencePanes/Hazel.prefPane' and '$HOME/Library/PreferencePanes/Hazel.prefPane'.
	Please remove one."

	exit 1

elif [[ -e "/Library/PreferencePanes/Hazel.prefPane" ]]
then

	INSTALL_TO="/Library/PreferencePanes/Hazel.prefPane"

else

	INSTALL_TO="$HOME/Library/PreferencePanes/Hazel.prefPane"

fi

function check_install_location {

	if [ ! -e "$INSTALL_TO:h" ]
	then
		echo "$NAME: Trying to create $INSTALL_TO:h:"
		mkdir -p "$INSTALL_TO:h" 2>&1
	fi

	if [ -d "$INSTALL_TO:h" -a -w "$INSTALL_TO:h" ]
	then
			# This is what we want/hope/expect
		echo "$NAME: '$INSTALL_TO:h' exists as a directory and is writable."
	elif [ -d "$INSTALL_TO:h" -a ! -w "$INSTALL_TO:h" ]
	then
		echo "$NAME: '$INSTALL_TO:h' exists as a directory but it is NOT writable. Cannot continue."
		exit 1
	elif [ ! -e "$INSTALL_TO:h" ]
	then
		echo "$NAME: '$INSTALL_TO:h' does not exist and we failed to create it."
		exit 1
	elif [ -e "$INSTALL_TO" -a ! -w "$INSTALL_TO" ]
	then
			# Ths app (or whatever) was either installed by a .pkg (which probably ran under 'sudo')
			# or it was installed via the Mac App Store, which installs apps owned by 'root'
			# We _could_ try a 'mv' command via 'sudo' I suppose.
		echo "$NAME: '$INSTALL_TO' already exists but is not writable. To continue, we must remove it using administrator permissions:"

		if (( $+commands[trash] ))
		then
				# The 'trash' command will prompt for user permission if necessary
			trash "$INSTALL_TO"
		else # no 'trash' command
				# move the file to the trash, renaming it to use the $INSTALLED_VERSION and $INSTALLED_BUILD variables
				# if those variables are unset use zero (0) instead
			sudo mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION-0}.${INSTALLED_BUILD-0}.$INSTALL_TO:e"
		fi # 'trash' command

			# Check again to see if we've successfully removed it
		if [ -e "$INSTALL_TO" -a ! -w "$INSTALL_TO" ]
		then
			echo "$NAME: $INSTALL_TO exists, but is not writable, and we failed to remove it. Cannot continue"
			exit 1
		fi
	fi
}

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f2)

if [[ "$OS_VER" -lt "12" ]]
then

	## the 'official' URL for version 4.3.5 is a DMG:
	# 	URL='https://www.noodlesoft.com/Downloads/Hazel-4.3.5.dmg'
	## but this script assumes a ZIP file not a DMG. My personal archived version is at
	# 	URL='https://iusethis.luo.ma/hazel/old/Hazel-4.3.5.zip'
	## but the one from Hazel's Sparkle feed is currently still available at
	# 	URL='https://s3.amazonaws.com/Noodlesoft/Hazel-sparkle-4.3.5.zip'
	## so we'll use that one for now.
	#
	## Checksum for Hazel-4.3.5.zip / Hazel-sparkle-4.3.5.zip:
	#
	# sha256 = da9243ee965dbbbed1483373c047b48974135889db037e94fee15e2e695d1d9a
	#    md5 = f77fd65a61d6b4164600f1e7e516b946

	URL='https://s3.amazonaws.com/Noodlesoft/Hazel-sparkle-4.3.5.zip'
	LATEST_VERSION='4.3.5'
	RELEASE_NOTES='no'
	INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '4.0.0'`

else

	RELEASE_NOTES='yes'

		# If there's no installed version, output 4.0.0 so the Sparkle feed will give us the proper download URL
		## DO NOT SET TO ZERO
	INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '4.0.0'`

	XML_FEED="https://www.noodlesoft.com/Products/Hazel/generate-appcast.php?version=$INSTALLED_VERSION"

	INFO=($(curl -sfL "$XML_FEED" \
				| tr -s ' ' '\012' \
				| egrep '^(sparkle:version|url)=' \
				| head -2 \
				| awk -F'"' '/=/{print $2}'))

	LATEST_VERSION="$INFO[1]"

	URL="$INFO[2]"

		# If any of these are blank, we should not continue
	if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
	then
		echo "$NAME: Error: bad data received:
		INFO: $INFO
		LATEST_VERSION: $LATEST_VERSION
		URL: $URL
		"

		exit 1
	fi

fi

if [[ -e "$INSTALL_TO" ]]
then

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version >$LATEST_VERSION<"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

if [[ "$RELEASE_NOTES" == "yes" ]]
then
	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL='https://www.noodlesoft.com/release_notes'

		( echo -n "$NAME: Release Notes for Hazel " ;
			(curl -sfL "$RELEASE_NOTES_URL" | sed '1,/<h1>/d; /<\/ul>/,$d' ; echo '</ul>') |\
			lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: <${RELEASE_NOTES_URL}>\nURL: $URL" ) | tee "$FILENAME:r.txt"
	fi
fi


if [[ -f "$FILENAME" ]]
then

	## The server does not support resuming downloads, so if we have the zip file, we need to test it
	## to see if it is valid. If yes, we keep it. If no, we delete it and download fresh

	(command unzip -l "$FILENAME" 2>&1 )>/dev/null

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then
		echo "$NAME: '$FILENAME' is a valid zip file."

	else
		echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

		mv -fv "$FILENAME" "$HOME/.Trash/"

		mv -fv "$FILENAME:r".* "$HOME/.Trash/"

	fi

fi

## so now if we do NOT have the filename, then we try to download it

if [[ ! -f "$FILENAME" ]]
then

		# Server does not support continued downloads, so assume that this is incomplete and try again
	[[ -f "$FILENAME" ]] && rm -f "$FILENAME"

	echo "$NAME: Downloading '$URL' to '$FILENAME':"

	curl --continue-at - --fail --location --output "$FILENAME" "$URL"

	EXIT="$?"

		## exit 22 means 'the file was already fully downloaded'
	[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

	[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

	[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

fi

	# If we get here we are ready to install
	# let's make sure we can
check_install_location

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

PID=$(pgrep -x 'HazelHelper')

if [[ "$PID" != "" ]]
then
	echo "$NAME: Quitting HazelHelper:"
	LAUNCH_HELPER='yes'
		# try to quit HazelHelper nicely
	osascript -e 'tell application "HazelHelper" to quit'
		# give it a chance to exit
	sleep 10
		# if it's still running, kill it
	pgrep -qx HazelHelper && pkill HazelHelper
else
	LAUNCH_HELPER='no'
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

if [[ "$LAUNCH_HELPER" == "yes" ]]
then

	if (is-growl-running-and-unpaused.sh)
	then

		growlnotify  \
			--appIcon "HazelHelper" \
			--identifier "$NAME" \
			--message "Launching Hazel Helper" \
			--title "$NAME" 2>/dev/null
	fi

	echo "$NAME: Launching HazelHelper..."

	open -a "$INSTALL_TO/Contents/MacOS/HazelHelper.app"
fi

exit 0
#
#EOF
