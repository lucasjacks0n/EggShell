# EggShell (Community fork)

## About
This fork is a actively updated and reviewed fork of the original eggshell project, which was abandoned and became outdated.
EggShell is a post exploitation surveillance tool written in Python. It gives you a command line session with extra functionality between you and a target machine. EggShell gives you the power and convenience of uploading/downloading files, tab completion, taking pictures, location tracking, shell command execution, persistence, escalating privileges, password retrieval, and much more.  This is project is a proof of concept, intended for use on machines you own.

## Getting Started
- Python 3.0 or higher

### macOS/Linux Installation
```sh
git clone https://github.com/rpwnage/eggshell-community-fork egshell
cd eggshell
python3 eggshell.py
```

## Creating Payloads
Eggshell payloads are executed on the target machine.  The payload first sends over instructions for getting and sending back device details to our server and then chooses the appropriate executable to establish a secure remote control session.

### bash
Selecting bash from the payload menu will give us a 1 liner that establishes an eggshell session upon execution on the target machine

### teensy macOS (USB injection)
Teensy is a USB development board that can be programmed with the Arduino ide.  It emulates usb keyboard strokes extremely fast and can inject the EggShell payload just in a few seconds.
Selecting teensy will give us an arduino based payload for the teensy board.
After uploading to the teensy, we can use the device to plug into a macOS usb port.  Once connected to a computer, it will automatically emulate the keystrokes needed to execute a payload.

## Interacting with a session
After a session is established, we can execute commands on that device through the EggShell command line interface.
We can show all the available commands by typing "help"

## Taking Pictures
Both iOS and macOS payloads have picture taking capability. The picture command lets you take a picture from the iSight on macOS as well as the front or back camera on iOS.

### Tab Completion
Similar to most command line interfaces, EggShell supports tab completion.  When you start typing the path to a directory or filename, we can complete the rest of the path using the tab key.

## Multihandler
The Multihandler option lets us handle multiple sessions.  We can choose to interact with different devices while listening for new connections in the background.  
Similar to the session interface, we can type "help" to show Multihandler commands

## Featured
Featured in EverythingApplePro's video demonstrating an iOS 9.3.3 Webkit vulnerability used to run EggShell

## Special Thanks
- Linus Yang / Ryley Angus for the iOS Python package
- AlessandroZ for LaZagne

## DISCLAMER
By using EggShell, you agree to the GNU General Public License v2.0 included in the repository. For more details at http://www.gnu.org/licenses/gpl-2.0.html. Using EggShell for attacking targets without prior mutual consent is illegal. It is the end user's responsibility to obey all applicable local, state and federal laws. Developers assume no liability and are not responsible for any misuse or damage caused by this program.

## Commands

#### macOS
* **brightness**     : adjust screen brightness
* **cd**             : change directory
* **download**       : download file
* **getfacebook**    : retrieve facebook session cookies
* **getpaste**       : get pasteboard contents
* **getvol**         : get speaker output volume
* **idletime**       : get the amount of time since the keyboard/cursor were touched
* **imessage**       : send message through the messages app
* **itunes**         : iTunes Controller
* **keyboard**       : your keyboard -> is target's keyboard
* **lazagne**        : firefox password retrieval | (https://github.com/AlessandroZ/LaZagne/wiki)
* **ls**             : list contents of a directory
* **mic**            : record mic
* **persistence**    : attempts to re establish connection after close
* **picture**        : take picture through iSight
* **pid**            : get process id
* **prompt**         : prompt user to type password
* **screenshot**     : take screenshot
* **setvol**         : set output volume
* **sleep**          : put device into sleep mode
* **su**             : su login
* **suspend**        : suspend current session (goes back to login screen)
* **upload**         : upload file


#### iOS
* **alert**          : make alert show up on device
* **battery**        : get battery level
* **bundleids**      : list bundle identifiers
* **cd**             : change directory
* **dhome**          : simulate a double home button press
* **dial**           : dial a phone number
* **download**       : download file
* **getcontacts**    : download addressbook
* **getnotes**       : download notes
* **getpasscode**    : retreive the device passcode
* **getsms**         : download SMS
* **getvol**         : get volume level
* **home**           : simulate a home button press
* **installpro**     : install substrate commands
* **ipod**           : control music player
* **islocked**       : check if the device is locked
* **lastapp**        : get last opened application
* **locate**         : get device location coordinates
* **locationservice**: toggle location services
* **lock**           : simulate a lock button press
* **ls**             : list contents of a directory
* **mic**            : record mic
* **mute**           : update and view mute status
* **open**           : open apps
* **openurl**        : open url on device
* **persistence**    : attempts to re establish connection after close
* **picture**        : take picture through the front or back camera
* **pid**            : get process id
* **respring**       : restart springboard
* **safemode**       : put device into safe mode
* **say**            : text to speach
* **setvol**         : set device volume
* **sysinfo**        : view system information
* **upload**         : upload file
* **vibrate**        : vibrate device


#### Linux
* **cd**             : change directory
* **download**       : download file
* **ls**             : list contents of a directory
* **pid**            : get process id
* **pwd**            : show current directory
* **upload**         : upload file

