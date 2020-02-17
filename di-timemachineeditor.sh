#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Time Machine Editor
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-11-13

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

HOMEPAGE='https://tclementdev.com/timemachineeditor/'

INSTALL_TO='/Applications/TimeMachineEditor.app'

FEED='https://tclementdev.com/timemachineeditor/updates2.plist'

TEMPFILE="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM.plist"

curl -sfLS -o "$TEMPFILE" "$FEED"

INFO=($(defaults read "$TEMPFILE" | egrep -i ' (HumanVersion|Version|URL) =' | sort | awk '{print $NF}' | tr -d '"|;'))

LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"
LATEST_BUILD="$INFO[3]"

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL

	TEMPFILE: $TEMPFILE
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

# No RELEASE_NOTES_URL

# FILENAME=$HOME/Downloads/${${INSTALL_TO:t:r}-${LATEST_VERSION}_${LATEST_BUILD}.pkg

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.pkg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	# exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$FILENAME"
else
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1
fi

EXIT="$?"

if [ "$EXIT" != "0" ]
then

	echo "$NAME: installation of $PKG failed (\$EXIT = $EXIT)."

		# Show the .pkg file at least, to draw their attention to it.
	open -R "$FILENAME"

	exit 1
fi

exit 0

# /Applications/TimeMachineEditor.app:
# 	CFBundleShortVersionString: 5.0.4
# 	CFBundleVersion: 161
#
# https://tclementdev.com/timemachineeditor/updates_beta.plist
# https://tclementdev.com/timemachineeditor/updates_test.plist
# https://tclementdev.com/timemachineeditor/updates2.plist
#
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# <dict>
# 	<key>Items</key>
# 	<array>
# 		<dict>
# 			<key>Version</key>
# 			<integer>161</integer>
# 			<key>HumanVersion</key>
# 			<string>5.0.4</string>
# 			<key>URL</key>
# 			<string>https://tclementdev.com/timemachineeditor/TimeMachineEditor.pkg</string>
# 			<key>MinimumOSVersion</key>
# 			<string>10.9.0</string>
# 		</dict>
# 	</array>
# </dict>
# </plist>

exit 0
#EOF
