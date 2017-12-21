class command:
    def __init__(self):
        self.name = "dhome"
        self.description = "simulate a double home button press"
    
    def run(self,session,cmd_data):
    	cmd_data["cmd"] = "doublehome"
        error = session.send_command(cmd_data)
        if error:
        	print error