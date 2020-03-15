#!/usr/bin/env zsh -f
# Purpose: Download and install/update 1Password 7
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19; 2020-02-22 removed 1Password 6 support
# 		(use https://github.com/tjluoma/di/blob/master/discontinued/di-1password6.sh if needed)


# @TODO - find unmatched '"' after IS_AT_LEAST

NAME="$0:t:r"

PREFLIGHT="$HOME/.config/di/preflight.sh"

[[ -s "$PREFLIGHT" ]] && source "$PREFLIGHT"

	## NOTE: The app _must_ be installed at /Applications/ to work
INSTALL_TO="/Applications/1Password 7.app"

HOMEPAGE="https://1password.com"

DOWNLOAD_PAGE="https://1password.com/downloads/"

SUMMARY="Go ahead. Forget your passwords. 1Password remembers them all for you. Save your passwords and log in to sites with a single click. It's that simple."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

###############################################################################################

RELEASE_NOTES_URL='https://app-updates.agilebits.com/product_history/OPM7'

	# https://c.1password.com/dist/1P/mac7/1Password-7.4.3.pkg
URL=$(curl -sfLS --head 'https://app-updates.agilebits.com/download/OPM7' | awk -F' |\r' '/^.ocation:/{print $2}')

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#1Password-##g')

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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script." >>/dev/stderr
		echo "	See <https://apps.apple.com/us/app/1password-7-password-manager/id1333542190?mt=12> or" >>/dev/stderr
		echo "		<macappstore://apps.apple.com/us/app/1password-7-password-manager/id1333542190>" >>/dev/stderr
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>" >>/dev/stderr
		exit 1
	fi

else
	FIRST_INSTALL='yes'
fi

	## Note: 1Password seems to be made available in .pkg and .zip formats:
	## 		https://c.1password.com/dist/1P/mac7/1Password-7.4.3.zip
	## 		https://c.1password.com/dist/1P/mac7/1Password-7.4.3.pkg
	## The .pkg is smarter, despite being more complex to deal with

FILENAME="${DOWNLOAD_DIR-$HOME/Downloads}/1Password-${LATEST_VERSION}.pkg"

RELEASE_NOTES="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES" ]]
then

	cat "$RELEASE_NOTES"

elif (( $+commands[lynx] ))
then

	if [[ "$BETAS" == 'yes' ]]
	then

		RELEASE_NOTES_TEXT=$(curl -sfL "$RELEASE_NOTES_URL" \
		| sed "1,/class='beta'/d; /<article /,\$d" \
		| sed '1,/<\/h3>/d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nolist -nonumbers -stdin)

	else

		RELEASE_NOTES_TEXT=$(curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<article id="v[0-9]*"[ ]*>/d; /<\/article>/,$d' \
		| egrep -vi 'never prompts you for a review|If you need us, you can find us at|<a href="https://c.1password.com/dist/1P/mac7/.*">download</a>' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -nolist -nonumbers -stdin \
		| sed '/./,/^$/!d' )

	fi

	 echo "${RELEASE_NOTES_TEXT}\n\nSource: ${RELEASE_NOTES_URL}\nVersion : ${LATEST_VERSION}\nURL: $URL" | tee "$RELEASE_NOTES"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "${FILENAME}" "${URL}"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of '$URL' failed (EXIT = $EXIT)" >>/dev/stderr && exit 1

[[ ! -e "${FILENAME}" ]] && echo "$NAME: '${FILENAME}' does not exist." >>/dev/stderr && exit 1

[[ ! -s "${FILENAME}" ]] && echo "$NAME: '${FILENAME}' is zero bytes." >>/dev/stderr && rm -f "$FILENAME" && exit 1

egrep -q '^Local sha256:$' "$RELEASE_NOTES" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$RELEASE_NOTES" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 -p "$FILENAME:t" \
	)  >>| "$RELEASE_NOTES"
fi

# OS_VER=$(sw_vers -productVersion)
#
# OS_MINIMUM='10.12.6'
#
# autoload is-at-least
#
# is-at-least "$OS_MINIMUM" "$OS_VER"
#
# IS_AT_LEAST="$?"
#
# if [[ "$IS_AT_LEAST" != "0" ]]
# then
#
# 	echo "$NAME: Cannot use 1Password 7 with '$OS_VER' (requires at least '$OS_MINIMUM'). Use 1Password 6 instead." \
# 	| tee -a "${ERROR_DIR-$HOME/Desktop/${NAME}.error.txt"
#
# 	exit 1
# fi

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "${FILENAME}"

else
		## The requirement for 'sudo' means that this script can't be run unattended, which stinks.
		## If 'sudo 'fails for some reason, we'll just show the .pkg file to the user

	INSTALLER_LOG="${TMPDIR-/tmp}/${NAME}.${HOST}.installer.$RANDOM.log"

	echo "$NAME: Starting installation of '${FILENAME}'...\n\n" | tee -a "$INSTALLER_LOG"

	sudo /usr/sbin/installer -verbose -pkg "${FILENAME}" -dumplog -target / -lang en 2>&1 \
	| tee -a "$INSTALLER_LOG"
fi

# EXIT="$?"
#
# if [[ "$EXIT" != "0" ]]
# then
#
# 	open -R "${FILENAME}"
#
# 	echo "$NAME: installation failed on '$FILENAME' (\$EXIT = $EXIT)" \
# 	| tee -a "${ERROR_DIR-$HOME/Desktop/${NAME}.${HOST}.error.txt"
#
# 		# move the installer log to the ERROR_DIR/Desktop
# 	[[ -e "$INSTALLER_LOG" ]] && mv -vn "$INSTALLER_LOG" "${ERROR_DIR-$HOME/Desktop/"
#
# 	exit 1
# fi
#
# POSTFLIGHT="$HOME/.config/di/postflight.sh"
#
# [[ -s "$POSTFLIGHT" ]] && source "$POSTFLIGHT"

exit 0
#EOF
