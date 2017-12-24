from modules import helper as h
import threading

class MultiHandler:
	def __init__(self,server):
		self.server = server
		self.thread = None
		self.sessions = list()
		self.handle = h.COLOR_INFO + "MultiHandler" + h.ENDC + ">"
		self.start_background_server()
		self.interact()


	def background_worker(self):
		print "starting background worker\n"
		while 1:
			print "fuck"
			session = self.server.listen(True)
			if session:
				print "new connection!"


	def start_background_server(self):
		self.thread = threading.Thread(target=self.background_worker)
		self.thread.setDaemon(False)
		self.thread.start()

	def interact(self):
		while 1:
			try:
				input_data = raw_input(self.handle)
				if not input_data:
					continue
				cmd = input_data.split()[0]
				args = input_data[len(cmd):].rstrip()
				if cmd == "interact":
					print "we gotta fuckin interact"
				else:
					print "invalid command"

			except KeyboardInterrupt:
				print "fuckit"
				if self.thread:
					print "join thread"
					self.thread.join()
					print "exiting"
					return


