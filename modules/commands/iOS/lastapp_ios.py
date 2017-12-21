class command:
    def __init__(self):
        self.name = "lastapp"
        self.description = "get last opened application"
    
    def run(self,session,cmd_data):
        print session.send_command(cmd_data)
