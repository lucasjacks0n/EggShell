class command:
    def __init__(self):
        self.name = "mute"
        self.description = "update and view mute status"
        self.usage = "Usage: mute status|on|off"
    
    def run(self,session,cmd_data):
       	if not cmd_data['args'] or not cmd_data['args'] in ['status','on','off']:
       		print self.usage
       		return
       	if cmd_data['args'] == "status":
       		cmd_data = {'cmd':'ismuted','args':''}
       	elif cmd_data['args'] == "off":
       		cmd_data = {'cmd':'unmute','args':''}
        elif cmd_data['args'] == "on":
            cmd_data = {'cmd':'mute','args':''}
        error = session.send_command(cmd_data)
        if error:
        	print error