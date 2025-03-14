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

Yes, there are lots of other ways to do this:

[MacUpdater](https://www.corecode.io/macupdater/) seems like a better alternative to MacUpdate Desktop (one-time-fee versus subscription, and it seems to do better at finding apps which need to be updated).

[MacUpdate Desktop](http://www.macupdate.com/desktop) might be the easiest to use, but it’s $40/year, and seems to miss some apps that I use. Also, there’s no good way to tell it when to run, so it doesn’t solve the interruption problem. Also: although I have been working on these scripts for a long time, and I still use MacUpdate, there was a very troubling “experiment” which seemed to happen recently where MacUpdate was bundling additional software with downloads *and claiming it was a feature.* (See [Has MacUpdate fallen to the adware plague?](https://blog.malwarebytes.org/news/2015/11/has-macupdate-fallen-to-the-adware-plague/)) Every one of my scripts so far (and for the foreseeable future) downloads directly from the official website.

[Homebrew Cask](https://github.com/Homebrew/homebrew-cask) does the same thing that [Homebrew](https://github.com/Homebrew/brew) does, except for regular apps. Cask solves the automation problem, in that you can schedule it to run whenever you want, but the whole system is built around the idea that someone else (other than you) will notice when an update to an app is available, and then submit it to the maintainers. That might make sense if an app doesn’t have its own update system, but for those that do, why not use them directly? (n.b. Cask is now part of Homebrew itself, and it appears they are trying to do app _updates_ not just _installs_, so that’s definitely an improvement. But I still like my scripts better.)

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

## What’s Left

One of my personal favorite parts of this system is that when the script is finished, you are left with the original download which has been named in such a way that the app name and the version number are clear in the filename. No more looking into ~/Downloads/ and seeing “download.dmg” or “pf.zip” and having to try to guess or remember what apps those are, or if they are apps at all.

## Advanced Options

If you combine these scripts with [Keyboard Maestro](http://www.keyboardmaestro.com/main/), you could create a macro which will check for the update of an app after that app quits, which will minimize disruptions. (My biggest complaint about Sparkle updates is that they almost always interrupt you right after you just started to use an app, which is possibly the worst time to be interrupted.)

## Disclaimers and “Ones To Watch”

While it’s not particularly _likely_, it is _possible_ that any of these scripts could stop working for any number of reasons.

However, a few of them are more likely than others.

* [Dropbox](https://www.dropbox.com/) - has a silent self-updater, so it’s not a huge concern, but my method for checking the latest version of Dropbox is very fragile.
* [BusyCal](http://www.busymac.com/busycal/) and [BusyContacts](http://www.busymac.com/busycontacts/) - updating them causes an “Open” dialog to appear, for reasons which are unclear to me. I assume it has something to do with sandboxing, but I’m not sure. I’m also not sure what to do about it, so I just hit `ESC` whenever that happens.

### Update To Disclaimers (2018-08-02)

Dropbox checking is much improved, although it now does a very good job at self-updating, so it’s hardly a concern. Once you have it installed, it _will_ keep itself up-to-date.

For BusyCal and BusyContacts, I took some time to examine them with [unpkg](https://www.timdoug.com/unpkg/) and realized that by using a (very slightly modified) version of the [unpkg.py](https://github.com/tjluoma/unpkg/blob/master/unpkg.py) script that powers `unpkg`, I can install the apps directly _without_ using their installers. So far, it hasn’t seemed to cause any problems for me, so checkout `unpkg.py` if you want to avoid that weird “Installer.app opens for no real purpose” bug when updating those two apps.


## Update 2025-03-13

I've gone through and verified almost all of the scripts here to make sure they work, and update the ones that don't. There are now 280 verified scripts available. I think there are 3-4 that still need to be updated. If you find a script that doesn't work, please [open an issue](https://github.com/tjluoma/di/issues) to let me know.

## Renaming Apps

_Added 2018-08-06_

A goal of this project for me is to make it easy to install whichever version of an app you want, even if there are different versions.

However, now that this project has grown, some scripts were installing to the same location, e.g.

	di-carboncopycloner3.sh:INSTALL_TO='/Applications/Carbon Copy Cloner.app'
	di-carboncopycloner4.sh:INSTALL_TO='/Applications/Carbon Copy Cloner.app'
	di-carboncopycloner5.sh:INSTALL_TO='/Applications/Carbon Copy Cloner.app'

On one level this is _not_ a problem, because each script should be intelligent enough to avoid installing an older version
over a newer one, so if you ran `di-carboncopycloner3.sh` and `di-carboncopycloner5.sh`, `di-carboncopycloner3.sh` would
simply report that the already-installed version was “Up-To-Date”.

However, if you wanted to use [di-auto.sh](https://github.com/tjluoma/di/blob/master/di-auto.sh) to _only_ run scripts for
apps which are already installed, you would run into problems because finding `/Applications/Carbon Copy Cloner.app`
did not tell you which of the scripts you need to run to check for updates.

I decided that the best solution was to update scripts which intentionally install older versions to explicitly include the
(major) version number in the app name, so that they install their apps to different places.

For example:

	di-carboncopycloner3.sh:INSTALL_TO='/Applications/Carbon Copy Cloner 3.app'
	di-carboncopycloner4.sh:INSTALL_TO='/Applications/Carbon Copy Cloner 4.app'

and just leave the latest one to use the usual path:

	di-carboncopycloner5.sh:INSTALL_TO='/Applications/Carbon Copy Cloner.app'

That is what I have started to do whenever I have seen a duplicated INSTALL_TO.

Some apps specifically include a major version number in their installation, e.g.

	di-1password6.sh:INSTALL_TO='/Applications/1Password 6.app'
	di-1password7.sh:INSTALL_TO='/Applications/1Password 7.app'

Some developers have chosen to avoid this problem by adding a version number to a new version
even if the old version did not have one. For example:

	di-screens3.sh:INSTALL_TO="/Applications/Screens.app"
	di-screens4.sh:INSTALL_TO='/Applications/Screens 4.app'

### Guidance for Renaming Apps:

- No two scripts should ever install to the same place (`INSTALL_TO=`).

- If the app itself chooses to include a version number in its name, honor that (i.e. “1Password 6” or “1Password 7”)

- If we _know_ we are intentionally installing an older version (Dash, TextExpander, CarbonCopyCloner),
	_add_ a major version number to the _OLDER_ installation, and let the newer version keep whatever name it wants.

- An exception to the previous guidance  would be `di-screens3.sh` since `di-screens4.sh` added a version number.

### Guidance for Naming Scripts for Multiple Versions of Apps

When I started this project, I did not anticipate the issue of installing older versions of apps, and therefore I mostly avoided using version numbers in script names, even if the app itself used a number (for example, I think `di-1password.sh` previously installed “1Password 6.app”).

Now we are left with a quandary: should we use a generic name for installation of specific versions? Very often developers will change the Sparkle feeds for new major versions of the app, and sometimes even the _format_ changes (i.e. version 3 was a .dmg but version 4 is a .pkg).

I am currently leaning towards including the version number in the script filename.

This is slightly inconvenient, because it requires that you _know_ which version you want to install (it would be easier to just type `di-1password.sh` and just get the latest version of 1Password, rather than having to remember to use `di-1password7.sh`), but I think there is no good solution that will satisfy everyone and every instance, so we just have to make a choice and try to apply it consistently.

I suppose another alternative would be to have a `di-1password.sh` which looks to see if you have installed version 6 or 7 (or both), and then runs either/both `di-1password6.sh` and `di-1password7.sh`, or just `di-1password7.sh` if you are doing a clean install and don't have any version of 1Password installed. A more advanced version could even try to figure out which version you _should_ install for your version of Mac OS. I have a Mac mini running an older version of Mac OS, so I _have_ to use `di-1password6.sh` on that machine.

## How does this work? Give me the nerdy details.

See [the Advanced Nerdy Details](https://github.com/tjluoma/di/wiki/Advanced-Nerdy-Details) in the wiki.

Some documentation has been moved to the wiki, including:

* [Installation and Usage Guide](https://github.com/tjluoma/di/wiki/Installation-and-Usage)
* [A wishlist](https://github.com/tjluoma/di/wiki/Wishlist)
* [Developer information](https://github.com/tjluoma/di/wiki/Dear-Mac-Developers)

## Mac App Store Clarification

This project does not update or install Mac App Store apps. Use the **App Store.app** for that. You can use this command in Terminal.app:

	/usr/bin/open macappstore://showUpdatesPage

I have recently gone through all of the scripts that are available both as direct-downloads and via the Mac App Store, and added some
code to try to prevent the scripts from trying to update an app if it was installed from the Mac App Store.

(Realistically, an attempt to use the script to install an update “over” a Mac App Store version would probably fail anyway, due to permissions, but
I would rather err on the side of caution.)

## di-auto.sh and why it’s awesome

I’m sorry to admit that I never paid much attention to [di-auto.sh](https://github.com/tjluoma/di/blob/master/di-auto.sh) until recently.

That was a mistake, because it provided a big feature that I should have been more keen to
support from early on.

One of the biggest challenges with a project like this is that you end up with a bunch of scripts which are meant to download and install apps,
but you might not want to install _all_ of them.

That’s where [di-auto.sh](https://github.com/tjluoma/di/blob/master/di-auto.sh) comes in.

`di-auto.sh` will check all of the `di-` scripts, and only run the ones which will update apps that you have already installed.

You can even [run it via launchd](https://github.com/tjluoma/di/tree/master/launchd) and have it update your apps once a day, automatically.

Want to install a new app? Use one of the `di-` scripts, or just install it however you would have previously.

Alister Forbes made a few comments, including these:

	# Check if the INSTALL_TO exists.  If it does, add it to the list
	# This FAILS for Evernote and hazel
	LOC=`grep -m1 INSTALL_TO $i`

	# There must be a better way to do this.  We split on the = and then use rev to flip the string
	LOCATION=$(echo "$LOC" | cut -d'=' -f2 | cut -c 2- | rev | cut -c 2- | rev)

It took me awhile to figure out what Alister was doing. One of the great things about
shell scripting is that there are so many ways to do things, and it's also one of the
terrible things about shell scripting. If you aren’t in the same “zone” as whoever wrote
the original code, it can be a challenge to figure out the “Why?”.

I suspect this is true for just about any programming language.

Anyway, in short, Alister was trying to figure out a way to make it so that `di-auto.sh`
would run `di-` scripts to update your apps, but only if those apps were already installed.

He did this by checking the INSTALL_TO= line for each app, but it failed for some of them
because they used variables like "$HOME", most notably preference panes such as Hazel and Witch,
as they are most often installed to "$HOME/Library/PreferencePanes"

I finally figured out how to do this by using `eval`. But the original idea came from Alister,
and I owe him big time for that.

I have made some significant changes to the script, however. One of the biggest is that it no
longer keeps a 'di.lst' file which seems to have been a list of each script that matched an
app on the computer.

I’m not sure what purpose that was serving, and I tend to install and remove apps a lot, so
I didn’t really want a cache of apps that were installed “at some point”.

So my version of the script removes that feature.

Of course, the great thing about GitHub is that you can easily see how things have evolved,
so if you want to see how Alister did things, check out the history page at:

<https://github.com/tjluoma/di/commits/master/di-auto.sh>


## Integrated Beta Installations

When I started this project, I built separate scripts for “beta” or “nightly” versions of apps, and had them install to different locations, i.e **/Applications/iTerm Nightly.app** compared to **/Applications/iTerm.app**.

I’ve come to consider this a mistake, because, in reality, I have found that for each app I have a clear preference. I _either_ want the beta/nightly or the regular version, not both. In fact, having both installed actually caused problems with different launchers, etc. It was confusing and frustrating. It also meant that there could potentially be _two_ scripts (or three, in at least one cast) trying to install / check-for-updates against the same application, unless special care was taken to install the beta/nightly versions to a separate location, which added complexity to the code.

Instead, we can have a single script with a unified code base, and all we need to do is give the user a way to indicate if they would prefer the beta versions or not. The easiest and most-reliable way I could think to do this was to add a simple check to see if a file existed in the user’s `$HOME` directory. If the file exists, they want the beta/nightly versions. Otherwise, they get the regular versions. The files can be zero-byte files, and they are all contained within a single hidden folder (in `~/.config/di/`, to be specific). So there's no worries about cluttering up the `$HOME` directory, for people who might worry about such things.

If you’re looking for examples of how this is done, so far these scripts have code variations for optional beta installations:

1. di-1password7.sh
2. di-alfred3.sh
3. di-carboncopycloner5.sh
4. di-cyberduck.sh
5. di-handbrake.sh
6. di-imageoptim.sh
7. di-iterm.sh
8. di-karabiner-elements.sh
9. di-littlesnitch.sh
10. di-mailmate.sh
11. di-xquartz.sh

`di-cyberduck.sh` actually has two options: “nightly” or “beta”. (Right now they’re identical, but the potential is there.)

`di-handbrake.sh` is the most complicated (so far). This is due to the fact that the regular builds have an XML/RSS file which is used for updates, but the “nightly” builds do not. So there’s a _lot_ of code which has to be handled separately, but that’s accomplished fairly easily, all things considered.

`di-littlesnitch.sh` and `di-carboncopycloner5.sh` are interesting because they use the same RSS/XML feed for both the beta and regular releases, so choosing one becomes a matter of how we parse the `$XML_FEED`.

### “What if I forget that I told one of these scripts that I want to use the betas?”

Each script which has beta support changes the `$NAME` variable to `$NAME (beta releases)`. This should make it clear when the scripts are running which of them, if any, are checking for betas. Instead of output like this:

	di-alfred3: Up-To-Date (3.6.2/922)

it will appear like this:

	di-alfred3 (beta releases): Up-To-Date (3.6.2/922)

### “What if I change my mind and want to stop checking for beta/nightly versions?”

Simple! Just delete the corresponding file in `~/.config/di/`. Each file is clearly named, so there should be no confusion over which one to delete in order to stop using betas.

For most apps, you don’t need to do anything else. The script will keep on checking for new releases, and when the stable version passes the beta versions, you’ll start to get non-beta versions again.

However, there are some apps (HandBrake comes to mind, but ImageOptim is also guilty of this) where the version numbers are _so_ different that I would recommend these steps:

1.	Delete the appropriate “beta indicator” file in `~/.config/di/`
2.	Delete the currently installed version of the app. This can normally be accomplished by just dragging the app to the Trash. ♻️
3.	Re-run the script, and it will download and install the newest (non-beta) version of the app.
4.	Reboot, just to be sure. (That’s probably not actually necessary, but for those who prefer to be cautious, it won’t hurt.)

N.B. For step #2, I would recommend _against_ using any type of “App Cleaner” or uninstaller, unless it is specifically created by the developer. In most cases, you do _not_ want to delete the associated files in ~/Library/Preferences/ or wherever, because those will be used by the non-beta versions of the app when they are installed. Don’t worry if the app was installed with an installer, all you need to do is remove the main installation file (i.e. the app), and let the installer for the non-beta version deal with any residual files.

If you _are_ one of the people who _do_ like the install beta and stable versions of the same app, the good news is that the three installers which were previously a part of the main project are still available, they are just slightly “hidden” in the [discontinued](https://github.com/tjluoma/di/tree/master/discontinued) folder. But they should continue to work as they did before.

1.	di-iterm-nightly.sh
2.	di-imageoptim-beta.sh
3.	di-handbrake-nightly.sh

Feel free to use or modify them as you see fit.

I do believe having unified scripts which are capable of installing _either_ beta or stable builds is the best way to proceed for the future.

