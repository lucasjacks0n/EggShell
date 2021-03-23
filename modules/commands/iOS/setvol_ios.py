class command:
    def __init__(self):
        self.name = "setvol"
        self.description = "set device volume"
        self.usage = "Usage: volume <number>"

    def run(self, session, cmd_data):
        if not cmd_data['args']:
            print(self.usage)
            return
        print(session.send_command(cmd_data))
