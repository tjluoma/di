#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-01-14

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Turbo Boost Switcher Pro.app'

LATEST_VERSION=$(curl -sfLS "https://api.rugarciap.com/tbs_version_pro" \
-H "Accept: */*" \
-H "Accept-Language: en-us" \
-H "User-Agent: Turbo%20Boost%20Switcher%20Pro/1 CFNetwork/1121.1.2 Darwin/19.2.0 (x86_64)")

# 291

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | tr -dc '[0-9]')

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

	echo "$NAME: Cannot do a clean install without an URL"
	exit 0
fi

growlnotify --sticky \
	--appIcon "$INSTALL_TO:t" \
	--identifier "$NAME" \
	--message "New version of 'Turbo Boost Switcher Pro' available" \
	--title "$LATEST_VERSION (vs $INSTALLED_VERSION)"

exit 0
#EOF
