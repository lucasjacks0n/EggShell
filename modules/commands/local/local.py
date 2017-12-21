import os
from os.path import expanduser

class command:
    def __init__(self):
        self.name = "local"
        self.description = "Run local shell commands"
    
    def run(self,session,cmd_data):
        if not cmd_data['args']:
            print "Usage: local shell commands"
            return
        else:
            split_args = cmd_data['args'].split()
            if split_args[0] == "cd":
                path = cmd_data['args'][2:].strip()
                if not path:
                    path = expanduser("~")
                os.chdir(path)
            else:
            	os.system(cmd_data['args'])

