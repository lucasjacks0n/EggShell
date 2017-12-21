class command:
    def __init__(self):
        self.name = "say"
        self.description = "text to speach"
        self.usage = "Usage: say hello"
    
    def run(self,session,cmd_data):
    	if not cmd_data['args']:
    		print self.usage
        session.send_command(cmd_data)
