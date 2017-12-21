class command:
    def __init__(self):
        self.name = "cd"
        self.description = "change directory"
    
    def run(self,session,cmd_data):
        error = session.send_command(cmd_data)
        if error:
        	print error