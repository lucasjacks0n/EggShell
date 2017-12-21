class command:
    def __init__(self):
        self.name = "open"
        self.description = "open apps"
        self.usage = "Usage: open bundleid"
    
    def run(self,session,cmd_data):
    	if not cmd_data['args']:
    		print self.usage
        result = session.send_command(cmd_data)
        if result:
        	print result