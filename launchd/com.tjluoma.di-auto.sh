#!/bin/zsh -f
# Purpose: Run 'di-auto.sh' every day (assuming it is found in $PATH)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-06

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

ERROR_LOG="$HOME/Desktop/com.tjluoma.di-auto.log"

[ -e "${ERROR_LOG}" -a ! -s "${ERROR_LOG}" ] && rm -fv "${ERROR_LOG}"

function write_plist {

PLIST="$HOME/Library/LaunchAgents/com.tjluoma.di-auto.plist"

if [[ -e "$PLIST" ]]
then
	echo "$NAME: $PLIST already exists."
else

cat <<EOINPUT > "$PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.tjluoma.di-auto</string>
	<key>LowPriorityBackgroundIO</key>
	<true/>
	<key>LowPriorityIO</key>
	<true/>
	<key>ProcessType</key>
	<string>Standard</string>
	<key>ProgramArguments</key>
	<array>
		<string>${DI_AUTO_PATH}</string>
		<string>--update</string>
	</array>
	<key>RunAtLoad</key>
	<false/>
	<key>StandardErrorPath</key>
	<string>${ERROR_LOG}</string>
	<key>StandardOutPath</key>
	<string>/tmp/com.tjluoma.di-auto.log</string>
	<key>StartInterval</key>
	<integer>86400</integer>
</dict>
</plist>
EOINPUT

/bin/launchctl load "$PLIST"

fi

}

if (( $+commands[di-auto.sh] ))
then

	DI_AUTO_PATH=`which di-auto.sh`

	write_plist

else

	(echo "'di-auto.sh' not found in $PATH";
	 echo "You can download 'di-auto.sh' from 'https://raw.githubusercontent.com/tjluoma/di/master/di-auto.sh'") 2>&1 \
	| tee -a "$ERROR_LOG"
fi

[ -e "${ERROR_LOG}" -a ! -s "${ERROR_LOG}" ] && rm -fv "${ERROR_LOG}"

[ -e "${ERROR_LOG}" ] && open "${ERROR_LOG}"

exit 0
# EOF
