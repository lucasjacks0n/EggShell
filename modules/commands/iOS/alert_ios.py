import base64
import json

class command:
    def __init__(self):
        self.name = "alert"
        self.description = "make alert show up on device"
        self.type = "native"

    def run(self,session,cmd_data):
        title = raw_input("title: ")
        message = raw_input("message: ")
        session.send_command({"cmd":"alert","args":json.dumps({"title":title,"message":message})})
        return ""
