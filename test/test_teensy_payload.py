import unittest
from modules.payloads import bash_payload, teensy_payload
import pwn

class TestTeensyPayload(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        print "============ Testing Teensy Payload ============"

    def setUp(self):
        # setup payload for further tests
        self.payload = teensy_payload.payload()

        # disable pwntools log
        pwn.context.log_level = 'critical'
        
        # start proc
        self.eggshell_proc = pwn.process(["python", "eggshell.py"])

        # make payload
        self.eggshell_proc.sendline("3")
        self.eggshell_proc.sendline("2")

    def tearDown(self):
        self.eggshell_proc.kill()

    def test_teensy_instance(self):
        tp = teensy_payload.payload()
        print "== Instantiated teensy payload =="
        self.assertTrue(isinstance(self.payload, teensy_payload.payload))
        print "== Is a teensy payload, confirmed =="

    def test_teensy_properties(self):
        print "== Testing teensy properties =="
        self.assertTrue(self.payload.name == "Teensy macOS")