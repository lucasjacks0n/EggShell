class command:
    def __init__(self):
        self.name = "pwd"
        self.description = "show current directory"
    
    def run(self,session,cmd_data):
        print session.send_command(cmd_data)