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

[MacUpdate Desktop](http://www.macupdate.com/desktop) might be the easiest to use, but it’s $40/year, and seems to miss some apps that I use. Also, there’s no good way to tell it when to run, so it doesn’t solve the interruption problem. Also: although I have been working on these scripts for a long time, and I still use MacUpdate, there was a very troubling “experiment” which seemed to happen recently where MacUpdate was bundling additional software with downloads *and claiming it was a feature.* (See [Has MacUpdate fallen to the adware plague?](https://blog.malwarebytes.org/news/2015/11/has-macupdate-fallen-to-the-adware-plague/)) Every one of my scripts so far (and for the foreseeable future) downloads directly from the official website.

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

## What’s Left

One of my personal favorite parts of this system is that when the script is finished, you are left with the original download which has been named in such a way that the app name and the version number are clear in the filename. No more looking into ~/Downloads/ and seeing "download.dmg" or “pf.zip" and having to try to guess or remember what apps those are, or if they are apps at all.

## Advanced Options

If you combine these scripts with [Keyboard Maestro](http://www.keyboardmaestro.com/main/), you could create a macro which will check for the update of an app after that app quits, which will minimize disruptions. (My biggest complaint about Sparkle updates is that they almost always interrupt you right after you just started to use an app, which is possibly the worst time to be interrupted.)

## Disclaimers and “Ones To Watch”

While it’s not particularly _likely_, it is _possible_ that any of these scripts could stop working for any number of reasons. 

However, a few of them are more likely than others.

* [Dropbox](https://www.dropbox.com/) - has a silent self-updater, so it’s not a huge concern, but my method for checking the latest version of Dropbox is very fragile.
* [BusyCal](http://www.busymac.com/busycal/) and [BusyContacts](http://www.busymac.com/busycontacts/) - updating them causes an “Open” dialog to appear, for reasons which are unclear to me. I assume it has something to do with sandboxing, but I’m not sure. I’m also not sure what to do about it, so I just hit `ESC` whenever that happens.


## To-Do List

Here are some apps that I want to be able to update automatically, but can’t figure out how to (yet?):

1. [MakeMKV](http://www.makemkv.com) - Cannot find XML/Sparkle feed, although it has some method of checking for updates. [Forum Post](http://www.makemkv.com/forum2/viewtopic.php?f=4&t=9955&sid=d6856f9d8122781dd1bf1e629908f49b)

2. [Charles](https://www.charlesproxy.com/) - Ironically this is what I use for checking most apps that don’t have an easy to find Sparkle feed, but I’m not sure where _its_ feed is.

3. [Kindle for Mac](http://www.amazon.com/kindlemacdownload) - The non-Mac App Store version has a way to check for updates, but can’t figure out what it is.

4. [Google Chrome](https://dl-ssl.google.com/chrome/mac/stable/CHFA/googlechrome.dmg) - will update itself via `launchd`, so not a high priority item.


5. <del>Microsoft Office 2011</del> - Recently added. (Office 2016 to come.)

6. More TK?


## How does this work? Give me the nerdy details.

See [the Advanced](https://github.com/tjluoma/di/blob/master/Advanced.md) notes.


## Milestone - 100 apps!

On 2016-05-11, this project hit a significant (to me, at least) milestone, as it now supports 100 apps.

(There are actually 103 scripts, but at least a couple of them are not fully functional.)


## Installation and Use 

Right now there isn’t a super-easy way to do this, so you’ll have to follow the steps below.

(Steps #1 and #2 only need to be done the first time.)

The easiest way to use these scripts is to download the ones that you want and put them in `/usr/local/bin/`

1) If you have not used /usr/local/bin/ before you will need to create it:

	sudo mkdir -p /usr/local/bin/
	
2) Then, for most people who are the only users of their Macs, I recommend changing the ownership of `/usr/local/bin/`	to match your username, so you can easily add/edit files:

	sudo chown $LOGNAME /usr/local/bin/
	
3) Once you have done that, simply browse the list of apps and see which ones you want to install, then download them and save them to `/usr/local/bin/`. 

	(Tip: Look for the “Raw” button, shown here: 

	<img src='img/github-raw.jpg' alt='Raw button'> 

	to get the “raw” script without any HTML around it.)

4) **Here’s a crucial step:** Make sure you choose [di-all.sh](https://raw.githubusercontent.com/tjluoma/di/master/di-all.sh) as one of the scripts you want to install. It will run all of the other scripts that start with `di-` when you run it.

5) When you have saved all the ones that you want, make sure they are _executable_ by running this command:

	chmod a+x /usr/local/bin/di-*.sh
	
6) If you want these scripts to run automatically, you will need to install the `launchd` plist as well. **This only needs to be done once.**

The easiest way to install it is to run these commands, which you can copy/paste into Terminal:


Created the directory where the file needs to go:

	mkdir -p "$HOME/Library/LaunchAgents/"
	
Note: you won’t see any response after that command, it will just show you a new command prompt. That is OK.
	

Change directory into that new directory that you have created:

	cd "$HOME/Library/LaunchAgents/"

(Again, no response will be given)


Download the plist:

	curl --remote-name https://raw.githubusercontent.com/tjluoma/di/master/launchd/com.tjluoma.di-all.plist
	
You will see a brief progress bar that looks something like this:

	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100   391  100   391    0     0    445      0 --:--:-- --:--:-- --:--:--   444

Last, you need to tell `launchd` to load the plist:

	launchctl load $PWD/com.tjluoma.di-all.plist

I know that is an awkward series of steps, but it only needs to be done once. You can do it!

If you decide that you want more scripts, just download them to /usr/local/bin/.

If you decide that you no longer want a particular script, just delete the file.

## Here is an example for VLC and Bartender

Imagine that you wanted to install VLC and Bartender, and keep them up to date. 

1. Download [di-bartender.sh](https://raw.githubusercontent.com/tjluoma/di/master/di-bartender.sh) and [di-vlc.sh](https://raw.githubusercontent.com/tjluoma/di/master/di-vlc.sh) and save them to /usr/local/bin/

2. Download [di-all.sh](https://raw.githubusercontent.com/tjluoma/di/master/di-all.sh) and save it to /usr/local/bin/

	**Note: the ‘all’ in ‘di-all’ refers to ‘all that you have installed’ not ‘all available on Github’
	
3. Install `com.tjluoma.di-all.plist` as described above.

Now they will be automatically kept up-to-date. That's all you need to do!

If you decide that you want to add another app, for example: Evernote, simply download [di-evernote.sh](https://raw.githubusercontent.com/tjluoma/di/master/di-evernote.sh) and save it to /usr/local/bin/. Since you already have `di-all` and `launchd` configured, you don’t need to do anything else other than grab the new “di” file for the new app.






