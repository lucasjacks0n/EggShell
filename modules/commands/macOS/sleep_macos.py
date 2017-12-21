class command:
    def __init__(self):
        self.name = "sleep"
        self.description = "put device into sleep mode"

    def run(self,session,cmd_data):
    	cmd_data["cmd"] = "osascript"
    	cmd_data["args"] = " -e 'tell application \"Finder\" to sleep'"
        result = session.send_command(cmd_data)
        if result:
        	print result
