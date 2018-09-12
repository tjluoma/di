#!/bin/zsh -f
# Purpose: Download and install the latest version of Skype
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-22

NAME="$0:t:r"

INSTALL_TO="/Applications/Skype.app"

HOMEPAGE="https://www.skype.com/"

DOWNLOAD_PAGE="https://get.skype.com/go/getskype-skypeformac"

SUMMARY="Enjoy free voice and video calls on Skype or discover some of the many features to help you stay connected with the people you care about."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function use_v7 {

		# via https://go.skype.com/classic.skype
	URL='https://download.skype.com/macosx/bf9ccdd6b5b079049ff5a87419033ce3/Skype_7.59.37.dmg'
	LATEST_VERSION="7.59.0.37"
	ASTERISK='(Note that version 8 is also available.)'
	USE_VERSION='7'
}

function use_v8 {

	USE_VERSION='8'

	URL=$(curl -sfLS --head 'https://get.skype.com/go/getskype-skypeformac' \
		| awk -F'\r| ' '/^.ocation/{print $2}')

	LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

}

if [[ -e "$INSTALL_TO" ]]
then
		# if v7 is installed, check that. Otherwise, use v8
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion | cut -d. -f1)

	if [[ "$1" == "--force7" ]]
	then

		if [[ "$MAJOR_VERSION" -gt "7" ]]
		then
			echo "$NAME: Version $MAJOR_VERSION is installed. Removing it and installing to version 7."

			rm -rf "$INSTALL_TO" || sudo rm -rf "$INSTALL_TO"
		fi

		use_v7

	elif [[ "$MAJOR_VERSION" == "7" ]]
	then
		use_v7
	else
		use_v8
	fi
else
	if [ "$1" = "--use7" -o "$1" = "-7" -o "$1" = "--force7" ]
	then
		use_v7

	else
		use_v8
	fi
fi

	# If any of these are blank, we should not continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
fi

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

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

if (( $+commands[di-skypecallrecorder-private.sh] ))
then
		# if 'di-skypecallrecorder-private.sh' exists, run it.
		# n.b. that script can't be shared because the download link contains the user's registration code.
	di-skypecallrecorder-private.sh
fi

PLIST="$HOME/Library/Preferences/com.skype.skype.plist"

[[ -e "$PLIST" ]] && exit 0

## If there is no plist, create one.
## Basically, I want to make sure that Skype doesn't try to automatically force me to “upgrade” to version 8.
##
## That involves setting this, I think:
##
## 	<key>SKAllowStealthUpgrade</key>
##	<false/>
##
## but it's just as easy to create the whole plist from an example one I had around.

cat <<EOINPUT > "$PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AutoCollapseChatView</key>
	<true/>
	<key>AutoCollapseSidebar</key>
	<false/>
	<key>ChatViewIsCollapsed</key>
	<false/>
	<key>DialpadOpen</key>
	<false/>
	<key>DisableWebKitDeveloperExtras</key>
	<true/>
	<key>HasMigratedUserDefinedEvents_2</key>
	<true/>
	<key>HockeySDKAutomaticallySendCrashReports</key>
	<false/>
	<key>HockeySDKCrashReportActivated</key>
	<true/>
	<key>IncludeDebugMenu</key>
	<false/>
	<key>LastUserSidebarWidth</key>
	<real>200</real>
	<key>NSFullScreenMenuItemEverywhere</key>
	<false/>
	<key>NSSplitView Subview Frames MainSplitView</key>
	<array>
		<string>0.000000, 0.000000, 200.000000, 600.000000, NO, NO</string>
		<string>201.000000, 0.000000, 649.000000, 600.000000, NO, NO</string>
	</array>
	<key>NSStatusItem Preferred Position Item-0</key>
	<real>1000</real>
	<key>NSTreatUnknownArgumentsAsOpen</key>
	<string>NO</string>
	<key>NSWindow Frame DialpadMonitor</key>
	<string>154 154 207 234 0 0 1440 877 </string>
	<key>SKAllowStealthUpgrade</key>
	<false/>
	<key>SKAvatarCacheDiskCacheVersion</key>
	<integer>22</integer>
	<key>SKDisableWelcomeTour</key>
	<false/>
	<key>SKLocationDataCacheDiskCacheVersion</key>
	<integer>4</integer>
	<key>SKMacUserSkypeVersion</key>
	<string>7.59.0.37</string>
	<key>SKShowCallDebugAutomatically</key>
	<true/>
	<key>SKShowWelcomeTour</key>
	<false/>
	<key>SKUpgradedFromVersion</key>
	<string>7.56.0.776</string>
	<key>SKUpgradedWithUpgradeType</key>
	<integer>2</integer>
	<key>ShowDialpadOnLogin</key>
	<false/>
	<key>SidebarIsCollapsed</key>
	<false/>
	<key>WebKitDeveloperExtras</key>
	<false/>
</dict>
</plist>
EOINPUT

exit 0
#EOF
