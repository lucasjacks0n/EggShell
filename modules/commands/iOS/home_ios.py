class command:
    def __init__(self):
        self.name = "home"
        self.description = "simulate a home button press"
    
    def run(self,session,cmd_data):
        error = session.send_command(cmd_data)
        if error:
        	print error