# di - [D]ownload and [I]nstall Mac apps

If you buy apps from the Mac App Store, then getting updates is fairly easy. (For all of its problems, the Mac App Store does updates pretty well.)

However, there are ***a lot*** of good apps -- maybe even the majority of good apps -- which aren’t available in the Mac App Store. 

Installing those apps means:

1.	going to Google to find the appropriate website (not always easy because, especially if app has a common name, or if the search results have a lot of other download sites before the official site.)

2.	finding the download link (not always easy)

3.	downloading the app (easy, but sometimes slow, due to a slow server or slow Internet connection)

4.	unzipping .zip files (or tbz files, etc) or mounting .dmg files, then copying them to /Applications/ (and un-mounting DMGs)

Most apps have an update system, **but they usually want to update at the least convenient time: right after you launch them, when you are trying to use them for something.**

Wouldn’t it be better if you could check for updates right after an app _quits?_ Or check in the middle of the night or when your computer isn’t in use?

That’s what these scripts allow you to do.

(Note: _Technically_ these scripts do three things: Download, Install, and _Update_; but I didn’t want to prefix them with [dui](https://en.wikipedia.org/wiki/Driving_under_the_influence) and `diu` seemed awkward to type, so I went with a `di` prefix.)

## “But what about…?”

There are lots of other ways to do this.

[MacUpdate Desktop](http://www.macupdate.com/desktop) might be the easiest to use, but it’s $40/year, and seems to miss some apps that I use. Also, there’s no good way to tell it when to run, so it doesn’t solve the interruption problem. Also: although I have been working on these scripts for a long time, and I still use MacUpdate, there was a very troubling “experiment” which seemed to happen recently where MacUpdate was bundling additional software with downloads *and claiming it was a feature.* (See [Has MacUpdate fallen to the adware plague?](https://blog.malwarebytes.org/news/2015/11/has-macupdate-fallen-to-the-adware-plague/).) Every one of my scripts so far (and for the foreseeable future) downloads directly from the official website.

[Homebrew Cask](http://caskroom.io/) does the same thing that [Homebrew](http://mxcl.github.com/homebrew/) does, except for regular apps. Cask solves the automation problem, in that you can schedule it to run whenever you want, but the whole system is built around the idea that someone else (other than you) will notice when an update to an app is available, and then submit it to the maintainers. That might make sense if an app doesn’t have its own update system, but for those that do, why not use them directly?

[AutoPkg](https://github.com/autopkg/autopkg) is a super-powerful system that can probably do far more than my system can. But it’s also a lot more complicated.

I wanted something different than all of the above.

## My Way

_Most_ third-party Mac apps use [Sparkle](http://sparkle-project.org/) to check for updates. 

Sparkle uses a standardized XML-based RSS feed that includes all of the information that I need to check to see if I have the latest version of an app, or a quick way to install the latest version of an app if it isn’t installed.

I can check the Sparkle feed for the latest version of the app and compare it to the locally installed version using Unix tools which come standard with every Mac. In almost all cases, you should be able to take one of these `di` scripts and run it on a freshly-installed Mac and it will download & install the latest version for you.

## Multiple Macs?

Have several Macs? You can run `di` scripts over `ssh` and update any Mac you want, without needing to worry about doing separate setup for each one.

If you are behind a slow or metered Internet connection, or do you just not want to re-download each app update separately, you can easily sync your `~/Downloads/` folder using [BitTorrent Sync](http://www.bittorrent.com/sync/). Each `di` script is designed to check `~/Downloads/` to see if the latest version of the app is already downloaded there and ready to be installed. (This also means that large downloads which are interrupted before they are finished can be resumed by re-running the script.)

## No Maintenance  (almost)

One of the best parts of this system is that once it is setup, it should not need any more work. The next time the script is run after an app is updated, it will notice the new version using the app’s own update mechanism. Then the rest of the process will continue as before. 

I’ve been using these scripts for a few years, and so far the only time they break is if a new major version of an app (i.e. version 5 vs version 6) uses a different Sparkle feed. That *usually* only requires updating one line of the script to point to the new feed URL.

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

