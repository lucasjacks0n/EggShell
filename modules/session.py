import json
import threading
import base64
import sys
import time
import binascii
import os
import modules.helper as h
import readline

class Session:
	def __init__(self,server,conn,device_info):
		self.server = server
		self.conn = conn
		self.name = device_info['name']
		self.type = device_info['type']
		self.uid = device_info['uid']
		self.last_tab = None

	def interact(self):
		readline.clear_history()
		readline.set_completer(self.tab_complete)
		readline.parse_and_bind('tab: complete')
		command_modules = self.server.get_modules(self)
		while 1:
			try:
				#prepare command
				raw = raw_input(self.name)
				if not raw or raw.replace(" ","") == "":
					continue
				cmd = raw.split()[0]
				cmd_data = {"cmd": cmd, "args":raw[len(cmd) + 1:]}

				# handle input
				if cmd == "exit":
					self.disconnect()
					return
				elif cmd == "help":
					self.show_commands()
				elif cmd in command_modules.keys():
					command_modules[cmd].run(self,cmd_data)
				elif cmd in self.server.modules_local.keys():
					self.server.modules_local[cmd].run(self,cmd_data)
				else:
					try:
						result = self.send_command(cmd_data)
						if result:
							print result.rstrip()
					except KeyboardInterrupt:
						self.send_command({"cmd":"killtask"})

			except KeyboardInterrupt:
				print ""
				if readline.get_line_buffer():
					continue
				self.disconnect()  
				return
			except Exception as e:
				print e


	def tab_complete(self, text, state):
		# TODO: tab complete 'ls ', use get_completer_delims
		try:
			is_double_tab = False
			current_text = readline.get_line_buffer()
			if self.last_tab and self.last_tab == current_text:
				is_double_tab = True
			self.last_tab = current_text

			# if no input do nothing
			if not current_text:
				return
			# get last input
			split_input = current_text.split()[-1]
			
			search_path = os.path.split(split_input)[0]
			search_text = os.path.split(split_input)[1]
			data = self.send_command({"cmd":"tab_complete","args":search_path if search_path else "."})
			results = json.loads(data)

			matched_keys = []
			if results:
				keys = results.keys()
				keys.sort()
				# append / if it is a directory				
				for k in keys:
					# continue if no match
					if k.startswith(search_text):
						matched_keys.append(k)

			# edge cases
			if not matched_keys:
				# don't do anything if we have no matches
				return
			elif len(matched_keys) == 1:
				# if there is only 1 match and that match is a directory, append a '/'
				readline.insert_text(matched_keys[0][len(search_text):])
				if matched_keys[0] in results:
					if results[matched_keys[0]] == 4 or results[matched_keys[0]] == 10:
						readline.insert_text("/")
				return
			elif not is_double_tab:
				# lcp of multiple matched
				find = h.find_longest_common_prefix(matched_keys)
				readline.insert_text(find[len(search_text):])
				return

			print ""
			for k in matched_keys:
				if results[k] == 4:
					print h.COLOR_INFO + k + h.ENDC
				elif results[k] == 10:
					print h.COLOR_INFO + k + h.ENDC
				else:
					print k
				# back to where we are
			sys.stdout.write(self.name + current_text)		
		except Exception as e:
			print "\n error - " + str(e)


	def show_commands(self):
		print h.WHITEBU+"Local Commands:"+h.ENDC
		names_local = self.server.modules_local.keys()
		names_local.sort()
		for key in names_local:
			h.show_command(self.server.modules_local[key])

		print "\n"+h.WHITEBU+"Device Commands:"+h.ENDC
		command_modules = self.server.get_modules(self)
		names = command_modules.keys()
		names.sort()
		for k in names:
			h.show_command(command_modules[k])


	def send_command(self,cmd_data):
		cmd_data["term"] = binascii.hexlify(os.urandom(8))
		self.sock_send(json.dumps(cmd_data))
		return self.sock_receive(cmd_data["term"])

		
	def download_file(self,path):
		raw = self.send_command({"cmd":"download","args":path})
		result = json.loads(raw)
		status = result['status']
		if status == 1:
			if 'size' in result:
				size = int(result['size'])
				return self.sock_receive_data(size)
		elif status == 0:
			print path + ": No such file or directory"
		elif status == 2:
			print path + " is a directory"


	def upload_file(self,file_path,remote_dir,remote_file_name):
		term = binascii.hexlify(os.urandom(16))
		if os.path.exists(file_path):
			f = open(file_path,"rb")
			data = f.read()
			size = len(data)
			name = os.path.split(file_path)[-1]
			cmd_data = json.dumps({"cmd":"upload","args":json.dumps({"size":size,"path":remote_dir,"filename":remote_file_name}),"term":term})
			self.sock_send(cmd_data)
			for i in range((size / 1024) + 1):
				deltax = i * 1024
				chunk = data[deltax:deltax + 1024]
				self.sock_send(chunk)
			self.sock_send(term)
		else:
			h.info_error("Local file: " + file_path + " does not exist")


	def sock_send(self,data):
		self.conn.send(data)


	def sock_receive(self,term):
		result = ""
		while 1:
			data = self.conn.recv(100).strip("\x00")
			has_term = term in data
			data = data.replace(term,"")
			if data != "":
				result += data
			if has_term:
				return result


	def sock_receive_data(self,size):
		term = binascii.hexlify(os.urandom(5))
		# here is the string son, hope you'll give it back
		self.sock_send(term)
		fdata = ""
		while 1:
			chunk = self.conn.recv(1024)
			if term in chunk:
				# thank you son
				chunk = chunk.replace(term,'')
				fdata += chunk
				return fdata[:size]
			fdata += chunk


	def disconnect(self):
		h.info_general("Closing session")
		self.conn.close()
		time.sleep(0.5)
