class command:
    def __init__(self):
        self.name = "setvol"
        self.description = "set device volume"
        self.usage = "Usage: volume 1.0"
    
    def run(self,session,cmd_data):
    	if not cmd_data['args']:
    		print self.usage
    		return
        session.send_command(cmd_data)
