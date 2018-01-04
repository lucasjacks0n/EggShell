from modules import helper as h
import json

class command:
    def __init__(self):
        self.name = "cd"
        self.description = "change directory"
    
    def run(self,session,cmd_data):
        result = json.loads(session.send_command(cmd_data))
        if 'error' in result:
        	h.info_error(result['error'])
        elif 'current_directory' in result:
        	session.current_directory = result['current_directory'].encode('utf-8')
        else:
        	h.info_error('unable to get current directory')