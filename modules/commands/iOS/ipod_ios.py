class command:
    def __init__(self):
        self.name = "ipod"
        self.description = "control music player"
        self.usage = "Usage: ipod play|pause|next|prev|info"
    
    def run(self,session,cmd_data):
    	if not cmd_data['args'] or not cmd_data['args'] in ['play','pause','next','prev','info']:
    		print self.usage
        result = session.send_command(cmd_data)
        if result:
        	print result.rstrip()