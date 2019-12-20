#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-12-20

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi

INSTALL_TO='/Applications/ChronoSync.app'

URL='https://downloads.econtechnologies.com/updates/CS4_Download.dmg'

FEED='https://www.econtechnologies.com/UC/updatecheck.php?prod=ChronoSync&vers=4.0&lang=en&plat=mac&os=10.14.1&hw=i64&req=1'

INFO=$(curl -sfLS "$FEED" |\
sed 's#<br>#\
#g')

LATEST_VERSION=$(echo "$INFO" | awk -F'=' '/^VERSION/{print $NF}')

RELEASE_NOTES_URL=$(echo "$INFO" | awk -F'=' '/^NOTICE/{print $NF}')

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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"




exit 0
#EOF
