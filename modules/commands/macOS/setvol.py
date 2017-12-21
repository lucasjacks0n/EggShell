class command:
    def __init__(self):
        self.name = "setvol"
        self.description = "set output volume"
     
    def run(self,session,cmd_data):
        if not cmd_data['args']:
            print "Usage: setvol 0-100"
            return -1
        payload = "set volume output volume "+cmd_data['args']
        cmd_data.update({"cmd":"applescript","args":payload})
        result = session.send_command(cmd_data)
        if result:
            print result