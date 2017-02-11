# [EggShell](http://lucasjackson.me/eggshell)

EggShell (formerly known as NeonEggShell) is an iOS and OS X surveillance tool written in python.  This tool creates an command line session with extra functionality like downloading files, taking pictures, location tracking, and gathering data on a target.  Communication between server and target is encrypted with a random 128 bit AES key. EggShell also has the functionality to switch between and handle multiple targets. This is a proof of concept project, intended for use on machines you own.


For detailed information and howto visit http://lucasjackson.me/eggshell

## Preview

[![Preview](http://lucasjackson.me/wp-content/uploads/2016/10/Screen-Shot-2016-10-13-at-12.43.52-PM.png)](http://lucasjackson.me/eggshell)


##Getting Started
```sh
git clone https://github.com/neoneggplant/EggShell
easy_install pycrypto
cd EggShell
python eggshell.py
```

##iOS Commands:
* **ls**             : list contents of directory
* **cd**             : change directories
* **rm**             : delete file
* **pwd**            : get current directory
* **download**       : download file
* **frontcam**       : take picture through front camera
* **backcam**        : take picture through back camera
* **getpid**         : get process id
* **vibrate**        : make device vibrate
* **alert**          : make alert show up on device
* **say**            : make device speak
* **locate**         : get device location
* **respring**       : respring device
* **setvol**         : set mediaplayer volume
* **getvol**         : view mediaplayer volume
* **isplaying**      : view mediaplayer info
* **openurl**        : open url on device
* **dial**           : dial number on device
* **battery**        : get battery level
* **listapps**       : list bundle identifiers
* **open**           : open app
* **persistence**    : installs LaunchDaemon - tries to connect every 30 seconds
* **rmpersistence**  : uninstalls LaunchDaemon
* **open**           : open app
* **installpro**     : installs eggshellpro to device


##EggShell Pro Commands
* **lock**           : simulate lock button press
* **wake**           : wake device from sleeping state
* **home**           : simulate home button press
* **doublehome**     : simulate home button double press
* **play**           : plays music
* **pause**          : pause music
* **next**           : next track
* **prev**           : previous track
* **togglemute**     : programatically toggles silence switch
* **ismuted**        : check if we are silenced or not
* **islocked**       : check if device is locked
* **getpasscode**    : log successfull passcode attempts
* **unlock**         : unlock with passcode
* **keylog**         : log keystrokes
* **keylogclear**    : clear keylog data
* **locationservice**: turn on or off location services


##OS X Commands
* **ls**             : list contents of directory
* **cd**             : change directories
* **rm**             : delete file
* **pwd**            : get current directory
* **download**       : download file
* **picture**        : take picture through iSight camera
* **getpid**         : get process id
* **openurl**        : open url through the default browser
* **idletime**       : get the amount of time since the keyboard/cursor were touched
* **getpaste**       : get pasteboard contents
* **mic**            : record microphone
* **brightness**     : adjust screen brightness
* **getfacebook**    : retrieve facebook cookies from safari
* **exec**           : execute command
* **encrypt**        : encrypt file
* **decrypt**        : decrypt file
* **persistence**    : attempts to connect back every 60 seconds
* **rmpersistence**  : removes persistence


##Local Commands
* **lls**            : list contents of local directory
* **lcd**            : change local directories
* **lpwd**           : get current local directory
* **lopen**          : open local directory
* **clear**          : clears terminal

##Notes
* Supports Python 2.7.x
* Expect Updates :)

##New in 2.0
* Rewritten for encrypted communication/optimization
* Smaller payloads
* NeonEggShell -> EggShell
* Fully open source
