#Helper
#created by lucas.py
#3-5-17
import sys
import base64

class Helper:
    
    def __init__(self):
        iswin = sys.platform.startswith('win')
        self.iswin = iswin
        #colors
        self.GREEN = '' if iswin else '\033[1;92m'
        self.RED = '' if iswin else '\033[1;91m'
        self.WHITE = '' if iswin else '\033[0;97m'
        self.ENDC = '' if iswin else '\033[0m'
        self.UNDERLINE_GREEN = '' if iswin else '\033[4;92m'
        self.WHITEBU = '' if iswin else '\033[1;4m'
        self.COLOR_INFO = '' if iswin else '\033[0;36m'
        self.NES = ('SELECT' if iswin else '\033[0;32m')+"EggShell"+self.WHITE+"> "
        #cmds
        self.CMD_CLEAR = 'cls' if iswin else 'clear'
        self.CMD_PWD = 'cd' if iswin else 'pwd'
        self.CMD_LS = 'dir' if iswin else 'ls'

    def strinfo(self,string):
        print self.strinfoGet(string)
    
    def strinfoGet(self,string):
        return self.COLOR_INFO+"[*]  "+self.WHITE+string

    def bben(self,s):
        return base64.b64encode(s)
