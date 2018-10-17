#!/bin/zsh -f
# Purpose: Download and install/update the latest Drafts.app for Mac
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-10-17

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# Drafts for Mac is in beta, so this will probably not work well and break often

INSTALL_TO='/Applications/Drafts.app'

INSTALLED_BUILD=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0')

LATEST_BUILD=$(curl -sfLS 'https://getdrafts.com/mac/beta/' | fgrep -i '<li>Version' | awk '{print $2}' | tr -d ',')

autoload msg

GROWL_APP='Drafts'

if [[ "$LATEST_BUILD" == "" ]]
then

	msg --sticky --url https://getdrafts.com/mac/beta/ "LATEST_BUILD is empty. Click to check webpage."

elif [[ "$INSTALLED_BUILD" == "$LATEST_BUILD" ]]
then

	msg "Drafts is up-to-date"

else

	msg --sticky --url https://getdrafts.com/mac/beta/ "Drafts is outdated. Click to view/download."
fi

exit 0
#EOF
