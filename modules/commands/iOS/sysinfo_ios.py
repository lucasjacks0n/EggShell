class command:
	def __init__(self):
		self.name = "sysinfo"
		self.description = "view system information"
    
	def run(self,session,cmd_data):
		print session.send_command(cmd_data)
