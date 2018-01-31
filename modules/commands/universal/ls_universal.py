import json
import modules.helper as h

class command:
    def __init__(self):
        self.name = "ls"
        self.description = "list contents of a directory"
        self.usage = "Usage: ls directory/path/"
    
    def run(self,session,cmd_data):
        if not cmd_data['args']:
            cmd_data['args'] = '.'
        data = session.send_command(cmd_data)
        try:
            contents = json.loads(data)
        except:
            print data
            return
        keys = contents.keys()
        keys.sort()
        for k in keys:
            if contents[k] == 4 or contents[k] == 10:
                print h.COLOR_INFO + k + h.ENDC
            else:
                print k
