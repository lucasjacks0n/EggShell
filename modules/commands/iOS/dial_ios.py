class command:
    def __init__(self):
        self.name = "dial"
        self.description = "dial a phone number"
        self.usage = "Usage: dial 1234567890"
    
    def run(self,session,cmd_data):
    	if not cmd_data['args']:
    		print self.usage
    		return
    	cmd_data.update({"cmd":"openurl","args":"tel://"+cmd_data['args']})
        session.send_command(cmd_data)
