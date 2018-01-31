import modules.helper as h

class command:
    def __init__(self):
        self.name = "persistence"
        self.description = "attempts to re establish connection after close"
        self.usage = "Usage: persistence install|uninstall"

    def run(self,session,cmd_data):
        if cmd_data['args'] == "install":
            h.info_general("Installing...")
        elif cmd_data['args'] == "uninstall":
            h.info_general("Uninstalling...")
        else:
            print self.usage
            return
        result = session.send_command(cmd_data)
        if result:
            h.info_error(result)