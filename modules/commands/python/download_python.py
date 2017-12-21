import json
import os
import modules.helper as h

class command:
	def __init__(self):
		self.name = "download"
		self.description = "download file"
		self.usage = "Usage: download file"
		self.type = "native"

	def run(self,session,cmd_data):
		if not cmd_data['args']:
			print self.usage
			return
		file_name = os.path.split(cmd_data['args'])[-1]
		h.info_general("Downloading {0}".format(file_name))
		data = session.download_file(cmd_data['args'])
		if data:
			# save to downloads
			h.info_general("Saving {0}".format(file_name))
			f = open(os.path.join('downloads',file_name),'w')
			f.write(data)
			f.close()
			h.info_general("Saved to ./downloads/{0}".format(file_name))
