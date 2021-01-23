#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Hazel
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-23 (2016-04-22 - changed from .dmg to .zip ; 2021-01-23 updated to support versions 10.10, 10.11, and 10.12)

NAME="$0:t:r"

HOMEPAGE="https://www.noodlesoft.com"

DOWNLOAD_PAGE="https://www.noodlesoft.com/Products/Hazel/download"

OLDER='https://www.noodlesoft.com/old-versions/'

SUMMARY="Hazel watches whatever folders you tell it to, automatically organizing your files according to the rules you create. Have Hazel move files around based on name, date, type, what site it came from and much more. Automatically sort your movies or file your bills. Keep your files off the desktop and put them where they belong."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

############################################################################################################

OS_VER=$(sw_vers -productVersion)

case "$OS_VER" in
	10.10*)
		URL='https://www.noodlesoft.com/Downloads/Hazel-4.2.9.dmg'
		LATEST_VERSION='4.2.9'
		EXPECTED_SHA256='321f6a909a9b7a1969bf6237b2e42cc5fb4df2bef131cc46f5582e933166f734'
	;;

	10.11*)
		URL='https://www.noodlesoft.com/Downloads/Hazel-4.3.5.dmg'
		LATEST_VERSION='4.3.5'
		EXPECTED_SHA256='a96240c700f4954c1c0f51a1cc3ae0d0e29129df0cb26810a1cbdade760f7ae2'
	;;

	10.12*)
		URL='https://www.noodlesoft.com/Downloads/Hazel-4.4.5.dmg'
		LATEST_VERSION='4.4.5'
		EXPECTED_SHA256='19f0a193831b8d61b8b3a5e87ab08e5295e4e7680d13615ed5b14b34f60c3cef'
	;;

	10.*)

		echo "$NAME: macOS versions older than 10.10 are not supported." >>/dev/stderr
		echo "	See <https://www.noodlesoft.com/old-versions/> for downloads." >>/dev/stderr

		exit 1
	;;

	*)
		echo "$NAME: not compatible with macOS versions after 10.15 (Catalina)." >>/dev/stderr
		echo "	Use version 5 for Big Sur and later <https://www.noodlesoft.com/>" >>/dev/stderr

		exit 1
	;;

esac

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

############################################################################################################

if [ -e "/Library/PreferencePanes/Hazel.prefPane" -a -e "$HOME/Library/PreferencePanes/Hazel.prefPane" ]
then

	echo "$NAME: Hazel.prefPane is installed at _BOTH_ locations:" >>/dev/stderr
	echo "	/Library/PreferencePanes/Hazel.prefPane" >>/dev/stderr
	echo "	$HOME/Library/PreferencePanes/Hazel.prefPane" >>/dev/stderr
	echo "Please remove at least one." >>/dev/stderr

	exit 1

elif [[ -e "/Library/PreferencePanes/Hazel.prefPane" ]]
then

	INSTALL_TO="/Library/PreferencePanes/Hazel.prefPane"

else
		## If you want to install Hazel for all users, replace 'INSTALL_TO=' with this line
		# INSTALL_TO='/Library/PreferencePanes/Hazel.prefPane'

	INSTALL_TO="$HOME/Library/PreferencePanes/Hazel.prefPane"

fi

############################################################################################################

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

############################################################################################################

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

############################################################################################################

SHORT="$URL:t"

FILENAME="$HOME/Downloads/${SHORT}"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

############################################################################################################

ACTUAL_SHA256=$(shasum -a 256 "$FILENAME" | awk '{print $1}')

if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]
then

	echo "$NAME: sha256 verification failed:" >>/dev/stderr
	echo "$NAME: Actual sha256:		$ACTUAL_SHA256" >>/dev/stderr
	echo "$NAME: Expected sha256:	$EXPECTED_SHA256" >>/dev/stderr
	exit 1

fi

############################################################################################################

echo "$NAME: Mounting $FILENAME:"

	# Accept the EULA and mount the DMG
MNTPNT=$(echo -n "Y" \
		| hdid -plist "$FILENAME" 2>/dev/null \
		| fgrep '/Volumes/' \
		| sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

############################################################################################################
#
# If we get here we are ready to install
# let's make sure we can

check_install_location

############################################################################################################

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

############################################################################################################

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
#
#EOF
############################################################################################################
