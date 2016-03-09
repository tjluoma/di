#!/bin/zsh -f
# Purpose: Download and Install latest MarsEdit
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# Should the app be launched after install?
	# set to 'yes' if that is what you prefer
	# if it is running already when this script is run
	# and an update is necessary, it will be automatically
	# relaunched after upgrade
LAUNCH='no'

	# Where should it be installed to?
INSTALL_TO='/Applications/MarsEdit.app'

	# If MarsEdit is already installed, check to see if it is up to date
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '3'`

	# This is the Sparkle feed for MarsEdit updates
XML_FEED='http://www.red-sweater.com/marsedit/appcast3.php'

	# Parse the Sparkle feed for information about the latest release
INFO=($(curl -sfL "$XML_FEED" \
| tr -s ' ' '\012' \
| egrep 'sparkle:shortVersionString=|url=' \
| head -2 \
| sort \
| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

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

	# This is where the latest version will be saved to
FILENAME="$HOME/Downloads/MarsEdit-${LATEST_VERSION}.zip"

echo "$NAME: Out of Date: $INSTALLED_VERSION vs $LATEST_VERSION\nDownloading $URL to $FILENAME"

	# Here is where we do the actual downloading
curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL" 2>/dev/null

EXIT="$?"

	## EXIT = 22 means "the file was already fully downloaded"
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

	# if the app is already installed
if [ -e "$INSTALL_TO" ]
then
		# if it is currently running, quit it (nicely!) and then move it out of the way
	pgrep -xq "MarsEdit" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "MarsEdit" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/MarsEdit.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

	# Test to see if the installation was successful
EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

		# If the app was already running,
		# or if the user set 'LAUNCH="yes"' above
		# then launch the app
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

# is MarsEdit Registered?

if [ "`defaults read com.red-sweater.marsedit ME3RegistrationSerialNumber 2>/dev/null`" = "" ]
then
	echo "$NAME: $INSTALL_TO is not yet registered. Licenses can be purchased from https://red-sweater.com/store/
	If you have lost your registration code, see https://red-sweater.com/support/"
fi

########################################################################################################################
##                                        NERD NOTE:                                                                ####
##
## If you want to automate registration of MarsEdit, you can do it by uncommenting the two' defaults write' lines 
## and adding in the relevant information between the 'quote marks'
#
# defaults write com.red-sweater.marsedit ME3RegistrationUserName 'YourNameHere'
# defaults write com.red-sweater.marsedit ME3RegistrationSerialNumber 'YourCodeHere'


exit 0
#EOF
