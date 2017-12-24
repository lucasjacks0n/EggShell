from modules import helper as h
import threading, socket

class MultiHandler:
	def __init__(self,server):
		self.server = server
		self.thread = None
		self.sessions = dict()
		self.handle = h.COLOR_INFO + "MultiHandler" + h.ENDC + "> "


	def background_worker(self):
		while 1:
			session = self.server.listen(True)
			if session:
				# if already connected
				if session.uid in self.sessions.keys():
					continue
				self.sessions[session.uid] = session
				print "new connection!"


	def start_background_server(self):
		self.thread = threading.Thread(target=self.background_worker)
		self.thread.setDaemon(False)
		self.thread.start()


	def list_sessions(self):
		i = 1
		for key in self.sessions:
			session = self.sessions[key]
			print str(i) + " " + session.name + " " + session.type
			i += 1


	def interact_with_session(self,args):
		if not args:
			print "Usage: interact (session number)"
			return
		try:
			keys = self.sessions.keys()
			key = keys[int(args) - 1]
			self.sessions[key].interact()
		except:
			h.info_error("Invalid Session")


	def interact(self):
		while 1:
			try:
				input_data = raw_input(self.handle)
				if not input_data:
					continue
				cmd = input_data.split()[0]
				args = input_data[len(cmd):].rstrip()
				if cmd == "interact":
					self.interact_with_session(args)
				elif cmd == "sessions":
					self.list_sessions()
				else:
					h.info_error("Invalid Command: " + cmd)

			except KeyboardInterrupt:
				if self.thread:
					socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((self.server.host,self.server.port))
					self.thread.join()
				return


