
# Advanced

This document contains some more advanced / nerdy details for those who may want to understand how things are being done “behind the scenes”.

## “How do you do this?”

If you need to make a new script like this, the only “difficult” part can be finding the URL to the Sparkle feed. Even then, most of the time this is a fairly easy process.

For example, if you want to find where the app `/Applications/Vellum.app/` checks for updates. Use the `defaults` command and look for URLs using `fgrep`

	defaults read /Applications/Vellum.app/Contents/Info \
	| fgrep http

You’ll get this output:

    SUFeedURL = "https://get.180g.co/updates/vellum/";
    
That’s the Sparkle feed (SU = Sparkle Update). Then it’s just a matter of checking that URL. I start with this:

		curl -sfL "https://get.180g.co/updates/vellum/"

and I look for a line line this: 

		<enclosure url="https:/180g.s3.amazonaws.com/downloads/Vellum-13101.zip" 
		sparkle:version="13101" 
		sparkle:shortVersionString="1.3.1" 
		length="25709021" 
		type="application/octet-stream"/>

There’s usually a lot more in the feed, but this is the important part. If there are multiple updates in the feed, check for the most recent one. (Most of the time it will just be the most recent version; sometimes there are a lot of versions, with the newest on top; sometimes there are a lot of versions with the newest on the bottom. Occasionally there’s one or two entries, which includes (1) the newest version and (2) an older version which only works on older versions of Mac OS X.

`enclosure url` will tell you where the actual download is.

`sparkle:version`  or `sparkle:shortVersionString` is used to show the current version number. To compare that to the local version, I use the `defaults` command again, and check for the two different kinds of “versions” that a Mac app can have:
	
	defaults read /Applications/Vellum.app/Contents/Info \
	| egrep -i 'CFBundleShortVersionString|CFBundleVersion'

which gives the result:

    CFBundleShortVersionString = "1.3.1";
    CFBundleVersion = 13101;

Usually the `CFBundleShortVersionString` is more “human readable” and the `CFBundleVersion`. Some apps use the same version number for both. I tend to use the `CFBundleShortVersionString` because it’s more user-friendly, but _occasionally_ a developer will increment the `CFBundleVersion` for the same `CFBundleShortVersionString` (I don’t know why they would do that, but sometimes they do.)

Once you decide which one you want to use, you can get it directly using the `defaults` command:

	defaults read '/Applications/Vellum.app/Contents/Info' CFBundleShortVersionString

will output

	1.3.1

Then it’s just a matter of comparing the installed version (`defaults`) to the newest version (from the Sparkle feed).

In order to do that, I use a zsh feature called `is-at-least`:

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

I output the `$INSTALLED_VERSION` and `$LATEST_VERSION` so I can look at it and make a quick “sanity check” if I am running the script manually.

## Error Checking

Most of the scripts do at least some sort of minimal error-checking, but this is probably an area for potential improvement in most of the scripts.

One important thing to note is that if you want to run these scripts via `launchd` then you should always make sure that the script will do an `exit 0` or else `launchd` might stop running the script and you might not notice.

If you do implement better error checking, it would be best to redirect the error to a log file somewhere you will notice (such as `~/Desktop/` if yours isn’t too crowded) or send a notification using [Growl](https://itunes.apple.com/app/growl/id467939042), [terminal-notifier](https://github.com/alloy/terminal-notifier), or [Pushover](https://pushover.net/).

## Installation

Installing the apps is done via `ditto`. For `.zip` files that is usually as easy as this:

	ditto --noqtn -xk "foo.zip" "/Applications/"

`--noqtn` means “Do not preserve quarantine information” which prevents you from having to see the “You downloaded this app from the Internet, are you sure you want to launch it?” message that OS X shows.

For other files, such as those on DMGs, installation is done by:

	ditto --noqtn '/Volumes/foo/foo.app' '/Applications/foo.app'

The `'` marks aren’t _technically_ necessary unless there are spaces or some punctuation in the filenames, but better safe than sorry.

## Mounting DMGs

Mounting a DMG in a shell script is fairly easy. Assuming a file named `foo.dmg` use:

	hdiutil attach -nobrowse -plist "foo.dmg" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g'

and you will end up with the mount name, which is usually something like `/Volumes/Foo/`.

The only trick is if the DMG is prevented from loading because there is a EULA which you have to agree to before it will mount. Those are stupid (and can be defeated if you really want to), but some people still use them. In that case, you need to use `echo -n "Y"` to tell the DMG “yes” you agree to the EULA:

	echo -n "Y" \
	| hdid -plist "foo.dmg" 2>/dev/null \  
	| fgrep -A 1 '<key>mount-point</key>' \  
	| tail -1 \  
	| sed 's#</string>.*##g ; s#.*<string>##g'
	
	
