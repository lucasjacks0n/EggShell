import time
import getpass
import modules.helper as h

class command:
    def __init__(self):
        self.name = "su"
        self.description = "su login"
        self.type = "eggsu"

    def run(self,session,cmd_data):
        password = getpass.getpass("Password: ")
        cmd_data['args'] = password
        password = password.replace("\\","\\\\").replace("'","\\'")
        cmd_data['cmd'] = "eggsu"
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
