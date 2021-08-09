#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of Printopia v3
#
# From: Timothy J. Luoma
# Mail: luomat at gmail dot com
# Date: 2018-08-26

NAME="$0:t:r"

INSTALL_TO="/Applications/Printopia.app"

XML_FEED="https://www.decisivetactics.com/api/checkupdate?app_id=com.decisivetactics.printopia"

HOMEPAGE="https://www.decisivetactics.com/products/printopia/"

DOWNLOAD_PAGE="https://www.decisivetactics.com/products/printopia/"

# Direct: https://www.decisivetactics.com/products/printopia/get

SUMMARY="Wireless printing to any printer. Share any printer, old or new, with your iPad or iPhone."

zmodload zsh/stat #needed for zstat

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# we'll need this later to compare the download size to the expected size
function check_bytes { ACTUAL_BYTES=$(zstat -L +size "$FILENAME" 2>/dev/null || echo '0') }

function trash_our_files {

		# if the file FILENAME exists, put it in the trash with a warning to leave it alone
	[[ -e "$FILENAME" ]] && mv -f "$FILENAME" "$HOME/.Trash/$FILENAME:t:r.Corrupted-Do-Not-Use.$ACTUAL_SHASUM256.zip"

		# put the checksum file in the trash too
	[[ -e "$SHASUM_FILENAME" ]] && mv -vf "$SHASUM_FILENAME" "$HOME/.Trash/"

		# if we created a $RELEASE_NOTES_FILE, then we move that to the trash also
	[[ -e "$RELEASE_NOTES_FILE" ]] && mv -vf "$RELEASE_NOTES_FILE" "$HOME/.Trash/"

}

	# OK, so here's where we do the very clever parsing of our XML_FEED
	# which is fortunately very well-formed and easy to parse.
	#
	# So, we are creating a variable "$INFO" which will be split at newlines (IFS takes care of that)
	# we use egrep to limit the output only to the 8 fields we care about
	# we use 'head' to limit the output to the first 8 lines (8 fields of egrep, head -8, not a coincidence)
	# sed removes any whitespace at the beginning of the lines (that's a tab and a space in the [brackets]
	# tr gets rid of " and , characters (yes, 'sed' could do that, but I like using 'tr' as it seems more clear)
	# we use 'sort' to make sure that the 7 lines are in a predictable order, even if the order in the XML_FEED
	# 	changes at some point in the future
	# lastly we use awk to split each line at the spaces and get the 2nd field after each :
	# 	well-formed XML really makes things easier

	## 2018-10-03 - there's now a 'sha2_512' and 'sha3_512'.
	## 'sha2_512' can be calculated on a Mac with `shasum -a 256`
	## I am not sure how to calculate 'sha3_512'

IFS=$'\n' INFO=($(curl -sfLS "$XML_FEED" \
			| egrep '"app_version"|"app_version_short"|"sha1"|"sha2"|"sha2_512"|"size"|"team"|"url"' \
			| egrep -v '(https://www.decisivetactics.com/products/printopia/maintenance-expired|https://www.decisivetactics.com/products/printopia/release-notes-sparkle)' \
			| head -8 \
			| sed 's#^[	 ]*##g' \
			| tr -d '"|,' \
			| sort \
			| awk -F' ' '/:/{print $2}' ))

	# we assign “friendly names” to each line of $INFO so we can more easily refer to them later in the script
LATEST_BUILD="$INFO[1]"
LATEST_VERSION="$INFO[2]"

EXPECTED_SHASUM1="$INFO[3]"
EXPECTED_SHASUM256="$INFO[4]"
EXPECTED_SHASUM512="$INFO[5]"

EXPECTED_BYTES="$INFO[6]"
EXPECTED_CODESIGN_TEAM_ID="$INFO[7]"
URL="$INFO[8]"

## Useful for debugging, if needed. Uncomment and see if each of the values makes sense.
# echo "
# LATEST_BUILD: ${LATEST_BUILD}
# LATEST_VERSION: ${LATEST_VERSION}
# EXPECTED_SHASUM1: $EXPECTED_SHASUM1
# EXPECTED_SHASUM256: ${EXPECTED_SHASUM256}
# EXPECTED_SHASUM512: $EXPECTED_SHASUM512
# EXPECTED_BYTES: ${EXPECTED_BYTES}
# URL: ${URL}
# "

if [   "$LATEST_BUILD" = "" \
	-o "$LATEST_VERSION" = "" \
	-o "$EXPECTED_SHASUM1" = "" \
	-o "$EXPECTED_SHASUM256" = "" \
	-o "$EXPECTED_SHASUM512" = "" \
	-o "$EXPECTED_BYTES" = "" \
	-o "$EXPECTED_CODESIGN_TEAM_ID" = "" \
	-o "$URL" = "" ]
then

	echo "$NAME: Fatal Error! Bad data received:

	LATEST_BUILD: ${LATEST_BUILD}
	LATEST_VERSION: ${LATEST_VERSION}
	EXPECTED_SHASUM1: $EXPECTED_SHASUM1
	EXPECTED_SHASUM256: ${EXPECTED_SHASUM256}
	EXPECTED_SHASUM512: $EXPECTED_SHASUM512
	EXPECTED_BYTES: ${EXPECTED_BYTES}
	URL: ${URL}"

	exit 1

fi

if [[ -e "$INSTALL_TO" ]]
then

		# if the app is already installed, check to see if we are already running the latest version:

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

		# zsh feature that is useful for comparing version / build numbers
	autoload is-at-least

		# make sure what we have is at least what is on the server by comparing version numbers
	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

		# store the result in a variable
	VERSION_COMPARE="$?"

		# make sure what we have is at least what is on the server by comparing build numbers
	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

		# store the result in a variable
	BUILD_COMPARE="$?"

		# now, check that both of the exit codes for both of the comparisons indicate we are up-to-date
	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
			# all's good, we are current
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

		# if we get here, at least one (and probably both) of the version / build numbers
		# indicates that the server version is newer than our installed version. Time to upgrade!
	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

		# since we have found an existing installation, this clearly isn't the first time
		# that the app has been installed. We use this at the very end of the script
		# to determine some actions to take
	FIRST_INSTALL='no'

else

		# Save a variable telling us this _is_ the first time we have installed this app,
		# which we'll use later on to tell us we should launch the app if installation is a success

	FIRST_INSTALL='yes'
fi

	# This is where we will save the actual app (in zipped format) to
FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.zip"

cd "$FILENAME:h"

	# This is a file we will use to check the shasum of the .zip file after it is downloaded
	# it will contain the shasum value that we received from the XML_FEED, above
SHASUM_FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.shasum.txt"

	# this is a file we will use to share the release notes from the latest version
	# so that the user can read them at their leisure (the app might have been updated
	# automatically via launchd, and so the user would not see the release notes when
	# sent to 'stdout' below)
RELEASE_NOTES_FILE="$FILENAME:r.txt"

	# This is the URL where release notes are published
RELEASE_NOTES_URL="https://www.decisivetactics.com/products/printopia/release-notes-sparkle"

	# store the value of the shasum along the the full-path of the filename,
	# although the user may move it later.
cat <<EOINPUT > "$SHASUM_FILENAME"
$EXPECTED_SHASUM1 ?$FILENAME:t
$EXPECTED_SHASUM256 ?$FILENAME:t
$EXPECTED_SHASUM512 ?$FILENAME:t
EOINPUT

	# if the user has 'lynx' installed, we will use that to show them the release notes for this version
	# lynx does not come standard on macOS, but if the user is technically-savvy enough to be using
	# this script, it seems chances are good they might have lynx installed too.
if (( $+commands[lynx] ))
then

	(echo -n "$NAME: Release Notes for $INSTALL_TO:t:r " ;
		curl -sfLS "${RELEASE_NOTES_URL}" \
		| awk '/<h2>/{i++}i==1' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| sed '/./,/^$/!d' ; \
		echo "\nSource: <$RELEASE_NOTES_URL>") | tee "$RELEASE_NOTES_FILE"
else

		# if lynx is not found, tell the user where to find the release notes themselves

	(echo "$NAME [info]: 'lynx' is not installed, so release notes cannot be shown here, but see";
	 echo "		$RELEASE_NOTES_URL";
	 echo "	for release notes for this version of Printopia" ) | tee "$RELEASE_NOTES_FILE"
fi

	# Tell the user what we are using for the URL and the FILENAME
echo "$NAME: Downloading '$URL' to '$FILENAME':"

	# run 'check_bytes' to initialize the variable '$ACTUAL_BYTES'
check_bytes

	# initialize a counter, so the loop we enter doesn't go on forever
COUNT='0'

	# now we enter a loop where we keep trying to download the file ($FILENAME)
	# from the URL ($URL) until the actual local size (in bytes) of $FILENAME
	# matches what the XML_FEED told us the size should be
while [ "$EXPECTED_BYTES" -gt "$ACTUAL_BYTES" ]
do
		# increment the counter by 1
	((COUNT++))

		# if this loop has run 10 times, give up.
	[[ "$COUNT" -gt "10" ]] && break

	## Useful for debugging, if needed
	# echo "
	# ACTUAL_BYTES: 	$ACTUAL_BYTES
	# EXPECTED_BYTES: 	$EXPECTED_BYTES
	# COUNT: 			$COUNT
	# "

		# here is where we do the actual downloading, if all goes well
	curl --continue-at - --fail --location --output "$FILENAME" "$URL"

		# after 'curl' exits, we check the local size of the file again
	check_bytes

		# if the size is still too low, the loop will repeat
done

	# we are out of the loop now, check the size of the local file one last time
check_bytes

	# here's the big moment. Is the size correct?
if [[ "$ACTUAL_BYTES" == "$EXPECTED_BYTES" ]]
then
		# if we get here, the sizes match! Life is good!
	echo "$NAME: '$FILENAME' is the correct size ($ACTUAL_BYTES)."
else
		# if we get here, the sizes do NOT match. Tell the user, and then give up
	echo "$NAME: '$FILENAME' is the wrong size (Is $ACTUAL_BYTES bytes vs the expected size of $EXPECTED_BYTES bytes). Cannot continue."
	exit 1
fi

	# tell the user that we are checking the shasum
echo "$NAME: Verifying '$FILENAME' using 'shasum --check \"$SHASUM_FILENAME\"': "

	# and now actually check it. Note that this is checking against the file we created earlier
	# we could just compare against the shasum directly, but saving the shasum to a file
	# will allow the user to check it again later if they wish
	# Note that --check will verify all 3 of the shasums in the file at once, and report back for each,
	# something like this:
	#
	#	Printopia-3.0.11_03001.17.50.zip: OK
	# 	Printopia-3.0.11_03001.17.50.zip: OK
	# 	Printopia-3.0.11_03001.17.50.zip: OK
	#
	# so we don't need to call 'shasum --check' 3 times using each of the 3 shasums:
	#	shasum -a 1 --check "$SHASUM_FILENAME"
	#	shasum -a 256 --check "$SHASUM_FILENAME"
	#	shasum -a 512 --check "$SHASUM_FILENAME"
	# which is what I was originally doing before I realized it was superfluous
	# and I ended up with NINE lines telling me it was OK instead of 3
shasum --check "$SHASUM_FILENAME"

	# check to see what 'shasum' reported for an exit code
	# note that 'shasum' will also produce some output telling the user what happened
	# but we can't assume the user will be monitoring this script, or understand what to do
	# so we should do it for them, as best we can
SHA_EXIT="$?"

if [ "$SHA_EXIT" = "0" ]
then
		# tell the user the good news: the download has been verified
	echo "$NAME: '$FILENAME' passed shasum verification."

else
		# we hope to never get here, but if we do, verification has failed.
	echo "$NAME: '$FILENAME' failed shasum verification (SHA_EXIT = $SHA_EXIT)"

		# and then tell the user we will not be continuing with the installation
		# note that we purposefully have not touched their existing installation (if any)
		# before this point, so if they have a working installation of an older version
		# of the app, it will continue to function normally

		if [[ -e "$INSTALL_TO" ]]
		then
			echo "$NAME: Installation cancelled"
		else
			echo "$NAME: Upgrade cancelled"
		fi

		# if the downloaded file has failed validation, we probably shouldn't leave it sitting in their
		# ~/Downloads/ directory.
		#
		# So let's give it an obvious "THIS IS BAD DO NOT TOUCH"
		# name and move it to the Trash.
		#
		# An argument could be made that we should delete the file outright, since it might have malware in it
		# but I'm loathe to delete anything on another person's computer,
		# so putting it in the trash seems like a good compromise.

		# I created a function for this because we might need to do it later
		# even if we don't need to do it here
	trash_our_files

		# now we exit with code = 1 which the user can use if automating this process to tell
		# that something has gone wrong
	exit 1
fi

# PHEW. Ok, if we get here, we have a downloaded file that has passed a validation check
# now we need to unzip it and install it

	# create a temporary directory that we can use to unzip the $FILENAME into
UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

	# tell the user what we are doing:
echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

	# and now unzip the file using 'ditto'
	# we could use '/usr/bin/unzip' but I prefer 'ditto'. Because reasons. ¯\_(ツ)_/¯
ditto -xk "$FILENAME" "$UNZIP_TO"

DITTO_EXIT="$?"

if [[ "$DITTO_EXIT" == "0" ]]
then
		# tell the user that unzipping the file to the temporary folder was successful
	echo "$NAME: Unzip successful"
else
		# if we get here, ditto failed for some reason. Tell the user, and then give up
		#
		# Note that we still have not touched an existing installation, if any, so
		# if they had a functional installation of the app before, they still do,
		# even if it is now slightly outdated. Maybe they will try again
		# or maybe they have the app set to check for updates too, and it will
		# prompt them to try again later
	echo "$NAME failed (ditto exited = $DITTO_EXIT)"

		# we might as well delete this, since it is incomplete and no good to anyone
	rm -rf "$UNZIP_TO"

		# and, since 'ditto' failed to un-zip the file correctly
		# we should probably just get rid of the download

	trash_our_files

		# now we give up. We tried.
	exit 1
fi

# IF we get here, the unzip of the file $FILENAME into the temporary folder has succeeded
# NOW we are going to check the code signature of the newly un-zipped app, to make sure it
# passes before we touch their existing installation (if any)

	# Tell the user we are going to check the code signature of the newly-installed app
echo "$NAME: Checking code signature of '$UNZIP_TO/$INSTALL_TO:t'"

	# check the signature, but ignore the output, since it won't be meaningful to most people
	# we just want to check the exit code anyway
codesign -dv --verbose=4 "$UNZIP_TO/$INSTALL_TO:t" 2>/dev/null

CODE_SIGN_EXIT="$?"

if [ "$CODE_SIGN_EXIT" = "0" ]
then
		# tell the user that code signature passed, and how to check it themselves, if they want to
		# because hey, maybe they'll learn something useful
	echo "$NAME: $INSTALL_TO passed code signature check"
	echo "	(to view the information again later, use 'codesign -dv --verbose=4 $INSTALL_TO' after installation finishes)"

else
		# if we get here, something went wrong with code signature verification. We need to alert the user, and then give up
		# but first we should give them as much diagnostic information as possible, in case they decide to seek help

	echo "$NAME: code signature check FAILED (\$CODE_SIGN_EXIT = $CODE_SIGN_EXIT). Here is the full output of 'codesign':"

		# show them the output of the command this time. It still might not mean anything to them, but they can copy/paste
		# it into a support email, if they choose:

	codesign -dv --verbose=4 "$UNZIP_TO/$INSTALL_TO:t"

	echo "If you need more assistance, please contact Printopia’s developers (Decisive Tactics, Inc.) via https://www.decisivetactics.com/contact/"

		# there's no reason to leave the potentially-dangerous file around, so let's delete the entire unzip folder

	echo "$NAME: removing potentially hazardous files from '$UNZIP_TO'..."

	rm -rf "$UNZIP_TO"

		# given that the unzipped version of the file is bad, despite 'ditto' successfully un-zipping it
		# we should get rid of the files we downloaded / created rather than leaving them in the ~/Downloads/
		# folder where the user might find them and try to install them manually
	trash_our_files

	exit 1
fi

# Ok, so the general code signature check is OK, but is the TEAM in the signature the same as the
# TEAM in the XML_FEED? Let's check

ACTUAL_CODESIGN_TEAM_ID=$(codesign -dv --verbose=4 "$UNZIP_TO/$INSTALL_TO:t" 2>&1 | awk -F'=' '/^TeamIdentifier/{print $NF}')

if [[ "$ACTUAL_CODESIGN_TEAM_ID" == "$EXPECTED_CODESIGN_TEAM_ID" ]]
then
		# the codes match. We are good to go.
	echo "$NAME: Verified that the Team ID in the code signature matches (this is good)"

else

		# the teams do NOT match. Danger, Will Robinson.
	echo "$NAME: The Team IDs in the XML_FEED ($EXPECTED_CODESIGN_TEAM_ID) and the downloaded app ($ACTUAL_CODESIGN_TEAM_ID) do _NOT_ match (this is bad)."

	echo "$NAME: We cannot continue, and you should not use the downloaded files."

	echo "$NAME: removing potentially hazardous files from '$UNZIP_TO'..."

		# delete our temp directory and its contents
	rm -rf "$UNZIP_TO"

		# get rid of the downloaded file and related files
	trash_our_files

		# now we quit because we have no other choice, really
	exit 1
fi


# OK, if we have gotten here, we have passed all the hurdles except one:
#
# we need to deal with an existing & outdated installation, if any,
# before we can move the new version into its place

if [[ -e "$INSTALL_TO" ]]
then
		# if we get here, an older version of the app IS installed, so we are
		# going to have to deal with that

		# first we need to check to see if the app currently running.
		# If yes, try to get it to quit nicely, using AppleScript
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& echo "$NAME: Asking '$INSTALL_TO:t:r' to quit..." \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit" \
	&& sleep 5

		# If the app is STILL running,
		# try to kill it using 'pkill'
		# (I'm not sure how aggressive to get here.)
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& echo "$NAME: Asking '$INSTALL_TO:t:r' to quit (again)..." \
	&& pkill -f "$INSTALL_TO:t:r"

		# Now we check to see if the server component of Printopia is running
		# this is where the server portion is installed. We save it to a variable
		# so we can refer to it without needing to enter the whole path each time
		#
		# that way, if it changes locations in the future, we only need to change this one line
	PRINTOPIA_SERVER="/Library/Application Support/com.decisivetactics.printopia/Server/Printopia Server.app"

		# if the server portion is running, ask it to quit nicely, via AppleScript
	pgrep -qf "$PRINTOPIA_SERVER" \
	&& LAUNCH_SERVER='yes' \
	&& echo "$NAME: Asking '$PRINTOPIA_SERVER:t' to quit..." \
	&& osascript -e "tell application \"$PRINTOPIA_SERVER:t\" to quit" \
	&& sleep 5

		# if the server is still running, try to kill it with 'pkill'
		# Again, I'm not sure how much more aggressive we should be
		# I don't want to 'kill -9' it
	pgrep -qf "$PRINTOPIA_SERVER" \
	&& LAUNCH_SERVER='yes' \
	&& echo "$NAME: Asking '$PRINTOPIA_SERVER:t' to quit (again)..." \
	&& pkill -f "$PRINTOPIA_SERVER"

		# tell the user we are trashing their old installation
	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

		# move the existing installation to the trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	if [[ -e "$INSTALL_TO" ]]
	then
			# if we get here and the app is still where it was, something went wrong
			# so we alert the user, and then give up

		echo "$NAME: We failed to remove the existing version at '$INSTALL_TO'"
		echo "$NAME: Please remove the file manually, and then run this script again."
		exit 1
	fi
fi

	# tell the user we are moving the new version into place
echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# and now, actually do it:
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

MOVE_EXIT="$?"

if [[ "$MOVE_EXIT" = "0" ]]
then
		# if the move was successful, tell the user

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
		# if the move failed, tell the user, and give up
	echo "$NAME: mv failed ('mv' exit code = $MOVE_EXIT)"

	exit 1
fi

	# OK, if we get here, we have successfully installed or updated the software:
	# HUZZAH. Have a drink. Or not, depending on the time of day and any
	# other compelling reasons why that might be a bad idea.
	# I'm sorry I mentioned it.

if [[ "$FIRST_INSTALL" = "yes" ]]
then
		# if this is the first time the app has been installed,
		# launch it, so that it can be configured by the user
		# (I believe it needs to ask for some user permissions anyway)
	open -a "$INSTALL_TO"

		# exit, since there's nothing more for us to do
	exit 0
fi

	# If we get here, we have successfully upgraded an existing installation
	#
	# Now the question is: do we need to launch the app and/or the server?
	#
	# The answer will depend on what we found out earlier about whether the app
	# or its server portion were running and we told them to stop.

	# if the app was running when we installed the update, restart the app
[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

	# if the server was running when we installed the update, restart the server
[[ "$LAUNCH_SERVER" = "yes" ]] && open -a "$PRINTOPIA_SERVER"

	# That's it! I hope you have a nice day. 😃
exit 0
# EOF
