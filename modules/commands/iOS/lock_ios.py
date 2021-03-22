class command:
    def __init__(self):
        self.name         = "lock"
        self.description  = "simulate a lock button press"
        self.requiresPro  = True
    
    def run(self,session,cmd_data):
        error = session.send_command(cmd_data)
        if error:
        	print(error)