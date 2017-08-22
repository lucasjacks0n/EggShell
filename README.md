# [EggShell](http://lucasjackson.me/eggshell)

### About EggShell

EggShell is an iOS and macOS post exploitation surveillance pentest tool written in Python.  This tool creates 1 line multi stage payloads that give you a command line session with extra functionality. EggShell gives you the power and convenience of uploading/downloading files, taking pictures, location tracking, shell command execution, persistence, escalating privileges, password retrieval, and much more.  Server communication features end to end encryption with 128 bit AES and the ability to handle multiple clients. This is a proof of concept pentest tool, intended for use on machines you own.


For detailed information and howto visit http://lucasjackson.me/eggshell

Follow me on twitter: @neoneggplant

## Creating And Running A Payload
EggShell gives us a convenient 1 line payload and listener on our local machine

[![](http://lucasjackson.me/images/eggshell/2.2.1/startup1.png)](http://lucasjackson.me/eggshell)

On the target machine, after the payload is run, we will get a connection back

[![](http://lucasjackson.me/images/eggshell/2.2.1/runpayload.png)](http://lucasjackson.me/eggshell)

[![](http://lucasjackson.me/images/eggshell/2.2.1/connectback.png)](http://lucasjackson.me/eggshell)

## Taking Pictures
Eggshell has the command functionality of taking pictures on both iOS(frontcam/backcam) and macOS(picture)

[![](http://lucasjackson.me/images/eggshell/2.2.1/osxpicture.png)](http://lucasjackson.me/eggshell)

## Password Prompt / Root Privileges
With the prompt command, we can have a password pop up information retrieval + built in privilege escalation

[![](http://lucasjackson.me/images/eggshell/2.2.1/osxprompt.png)](http://lucasjackson.me/eggshell)

[![](http://lucasjackson.me/images/eggshell/2.2.1/escalateosx.png)](http://lucasjackson.me/eggshell)

## Sending SMS through iMessage
[![](http://lucasjackson.me/images/eggshell/2.2.1/osximessage.png)](http://lucasjackson.me/eggshell)

## Interacting With Multiple Sessions
MultiSession gives us easy access to interacting and managing multiple sessions

[![](http://lucasjackson.me/images/eggshell/multisessioninteractpictures.png)](http://lucasjackson.me/eggshell)

## Featured
Featured in EverythingApplePro's video demonstrating an iOS 9.3.3 Webkit vulnerability used to run EggShell

[![EverythingApplePro](http://lucasjackson.me/images/eggshell/2.2.1/featureeep.png)](https://www.youtube.com/embed/iko0bCVW-zk?start=209)

## DISCLAMER
By using EggShell, you agree to the GNU General Public License v2.0 included in the repository. For more details at http://www.gnu.org/licenses/gpl-2.0.html. Using EggShell for attacking targets without prior mutual consent is illegal. It is the end user's responsibility to obey all applicable local, state and federal laws. Developers assume no liability and are not responsible for any misuse or damage caused by this program.

## Installation
```sh
git clone https://github.com/neoneggplant/EggShell && cd EggShell
easy_install pycrypto
python eggshell.py
```

## iOS Commands:
* **sysinfo**        : get system information
* **cd**             : change directories
* **ls**             : list contents of directory
* **rm**             : delete file
* **pwd**            : get current directory
* **download**       : download file
* **upload**         : upload file
* **frontcam**       : take picture through front camera
* **backcam**        : take picture through back camera
* **mic**            : record microphone
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
* **getsms**         : download sms database
* **getnotes**       : download notes database
* **getcontacts**    : download addressbook
* **battery**        : get battery level
* **listapps**       : list bundle identifiers
* **open**           : open app
* **persistence**    : installs LaunchDaemon - tries to connect every 30 seconds
* **rmpersistence**  : uninstalls LaunchDaemon
* **open**           : open app
* **installpro**     : installs eggshellpro to device


## EggShell Pro Commands (iOS)
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


## macOS Commands
* **cd**             : change directories
* **ls**             : list contents of directory
* **rm**             : delete file
* **pwd**            : get current directory
* **download**       : download file
* **upload**         : upload file
* **getpaste**       : get pasteboard contents
* **mic**            : record mic
* **picture**        : take picture through iSight
* **screenshot**     : take screenshot
* **getfacebook**    : retrieve facebook session cookies
* **brightness**     : adjust screen brightness
* **getvol**         : get output volume
* **setvol**         : set output volume
* **idletime**       : get the amount of time since the keyboard/cursor were touched
* **keyboard**       : your keyboard -> is target's keyboard
* **imessage**       : send message through the messages app
* **openurl**        : open url through the default browser
* **play**           : tell iTunes to play
* **pause**          : tell iTunes to pause
* **prev**           : tell iTunes to play previous track
* **next**           : tell iTunes to play next track
* **pid**            : get process id
* **prompt**         : prompt user to type password
* **su**             : su login
* **persistence**    : attempts to connect back every 60 seconds
* **rmpersistence**  : removes persistence

## Local Commands
* **lls**            : list contents of local directory
* **lcd**            : change local directories
* **lpwd**           : get current local directory
* **lopen**          : open local directory
* **clear**          : clears terminal

## Notes
* Supports Python 2.7.x
* Expect Updates :)
