class command:
    def __init__(self):
        self.name = "islocked"
        self.description = "check if the device is locked"
    
    def run(self,session,cmd_data):
        print session.send_command(cmd_data)
