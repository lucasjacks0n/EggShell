from modules import helper as h
import threading, socket, time, sys

class MultiHandler:
	def __init__(self,server):
		self.server = server
		self.thread = None
		self.sessions = dict()
		self.session_uids = list()
		self.handle = h.COLOR_INFO + "MultiHandler" + h.ENDC + "> "
		self.is_running = False


	def background_worker(self):
		self.is_running = True
		id_number = 1
		while 1:
			if self.is_running:
				session = self.server.listen(True)
				if session:
					if session.uid in self.session_uids:
						# if already connected
						continue
					self.session_uids.append(session.uid)
					self.sessions[id_number] = session
					session.id = id_number
					id_number += 1
					sys.stdout.write("\n{0}[*]{2} Session {1} opened{2}\n{3}".format(h.COLOR_INFO,str(session.id),h.WHITE,self.handle))
					sys.stdout.flush()
			else:
				return


	def start_background_server(self):
		self.thread = threading.Thread(target=self.background_worker)
		self.thread.setDaemon(False)
		self.thread.start()


	def close_all(self):
		h.info_general("Cleaning up...")
		for key in self.sessions.keys():
			session = self.sessions[key]
			session.disconnect(False)


	def list_sessions(self):
		if not self.sessions:
			h.info_general("No active sessions")
		for key in self.sessions:
			session = self.sessions[key]
			print str(session.id) + " " + session.username + " " + session.type


	def interact_with_session(self,args):
		if not args:
			print "Usage: interact (session number)"
			return
		try:
			self.sessions[int(args)].interact()
		except:
			h.info_error("Invalid Session")


	def close_session(self,args):
		if not args:
			print "Usage: close (session number)"
			return
		try:
			session = self.sessions[int(args)]
			session.disconnect(False)
			h.info_general('Closing session ' + args)
		except Exception as e:
			print e
			h.info_error("Invalid Session")


	def stop(self):
		self.close_all()
		self.is_running = False
		if self.thread:
			socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((self.server.host,self.server.port))
			self.thread.join()
		time.sleep(0.5)


	def show_command(self,name,description):
		print name + " " * (15 - len(name)) + ": " + description


	def show_commands(self):
		commands = [
			("interact","interact with session"),
			("close","close active session"),
			("sessions","list sessions"),
			("exit","close all sessions and exit to menu"),
		]
		print h.WHITEBU+"MultiHandler Commands:"+h.ENDC
		for command in commands:
			self.show_command(command[0],command[1])


	def interact(self):
		h.info_general("Listening on port {0}...".format(self.server.port))
		h.info_general("Type \"help\" for commands")
		while 1:
			try:
				input_data = raw_input(self.handle)
				if not input_data:
					continue
				cmd = input_data.split()[0]
				args = input_data[len(cmd):].strip()
				if cmd == "interact":
					self.interact_with_session(args)
				elif cmd == "close":
					self.close_session(args)
				elif cmd == "sessions":
					self.list_sessions()
				elif cmd == "help":
					self.show_commands()
				elif cmd == "exit":
					self.stop()
					return
				else:
					h.info_error("Invalid Command: " + cmd)

			except KeyboardInterrupt:
				sys.stdout.write("\n")
				self.stop()
				return


