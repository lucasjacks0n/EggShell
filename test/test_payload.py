import unittest
from modules.payloads import bash_payload, teensy_payload

class TestPayload(unittest.TestCase):
    def test_bash_instance(self):
        bp = bash_payload.payload()
        print "== Instantiated bash payload =="
        self.assertTrue(isinstance(bp, bash_payload.payload))
        print "== Is a bash payload, confirmed =="

    def test_teensy_instance(self):
        tp = teensy_payload.payload()
        print "== Instantiated teensy payload =="
        self.assertTrue(isinstance(tp, teensy_payload.payload))
        print "== Is a teensy payload, confirmed =="