class command:
    def __init__(self):
        self.name = "suspend"
        self.description = "suspend current session (goes back to login screen)"

    def run(self,session,cmd_data):
    	cmd_data["cmd"] = ";"
    	cmd_data["args"] = '/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
        result = session.send_command(cmd_data)
        if result:
        	print result
