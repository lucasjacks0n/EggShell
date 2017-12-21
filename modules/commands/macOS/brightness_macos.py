class command:
    def __init__(self):
        self.name = "brightness"
        self.description = "adjust screen brightness"
        self.usage = "Usage: brightness 0.x"
        self.type = "native"
    
    def run(self,session,cmd_data):
        try:
            float(cmd_data["args"])
        except:
            print self.usage
            return
        session.send_command(cmd_data)
