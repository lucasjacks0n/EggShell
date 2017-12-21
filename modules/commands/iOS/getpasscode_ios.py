class command:
    def __init__(self):
        self.name = "getpasscode"
        self.description = "retreive the device passcode"
    
    def run(self,session,cmd_data):
        error = session.send_command(cmd_data)
        if error:
        	print error