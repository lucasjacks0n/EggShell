#Helper
#created by lucas.py
#3-5-17
import sys
import base64
import os
import socket

WINDOWS = sys.platform.startswith('win')
#colors
GREEN = '' if WINDOWS else '\033[1;92m'
RED = '' if WINDOWS else '\033[1;91m'
WHITE = '' if WINDOWS else '\033[0;97m'
GREEN_THIN = '' if WINDOWS else '\033[0;92m'
CYAN = '' if WINDOWS else '\033[0;96m'
YELLOW = '' if WINDOWS else '\033[0;93m'
ENDC = '' if WINDOWS else '\033[0m'
UNDERLINE_GREEN = '' if WINDOWS else '\033[4;92m'
WHITEBU = '' if WINDOWS else '\033[1;4m'
COLOR_INFO = '' if WINDOWS else '\033[0;36m'
NES = ('SELECT' if WINDOWS else '\033[0;32m')+"EggShell"+WHITE+"> "
#cmds
CMD_CLEAR = 'cls' if WINDOWS else 'clear'
CMD_PWD = 'cd' if WINDOWS else 'pwd'
CMD_LS = 'dir' if WINDOWS else 'ls'


def clear():
    os.system(CMD_CLEAR)


def info_general(string):
    print "{0}[*] {1}{2}".format(COLOR_INFO,WHITE,string)


def info_general_raw(string):
    return "{0}[*] {1}{2}".format(COLOR_INFO,WHITE,string)
    

def info_error(string):
    print "{0}[*] {1}{2}".format(RED,WHITE,string)


def info_warning(string):
    print "{0}[*] {1}{2}".format(YELLOW,WHITE,string)


def show_command(mod):
    print mod.name + " " * (15 - len(mod.name)) + ": " + mod.description


def b64(s):
    return base64.b64encode(s)


def getip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);s.connect(("192.168.1.1",80));host = s.getsockname()[0];s.close()
        host = host
    except:
        host = "127.0.0.1"
    return host


def find_longest_common_prefix(values):
    result = ""
    for i in range(len(values[0])):
        last = None
        for i in range(len(values)):
            m = values[i]
            if not last:
                last = m[0]
            else:
                if last != m[0]:
                    return result
            values[i] = values[i][1:]
        result = result + last
    return result


def generate_keys():
    print "Initializing server..."
    if not os.path.exists(".keys"):
        os.makedirs(".keys")
    os.system(
      "cd .keys;"+
      "openssl genrsa -out server.key 2048 2>/dev/null;"+
      "openssl req -new -key server.key -subj '/C=US/ST=EggShell/L=EggShell/O=EggShell/CN=EggShell' -out server.csr;"+
      "openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt 2>/dev/null")

    