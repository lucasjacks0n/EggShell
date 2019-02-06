import unittest
from modules.payloads import bash_payload, teensy_payload
import pwn

class TestPayload(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        print "============ Testing Payload ============"

    def setUp(self):
        # setup bash and teensy payloads for further tests
        self.bp = bash_payload.payload()
        self.tp = teensy_payload.payload()

        # disable pwntools log
        pwn.context.log_level = 'critical'
        
        # start proc
        self.eggshell_proc = pwn.process(["python", "eggshell.py"])

        # make payload
        self.eggshell_proc.sendline("3")

    def tearDown(self):
        self.eggshell_proc.kill()

    def test_bash_instance(self):
        print "== Instantiated bash payload =="
        self.assertTrue(isinstance(self.bp, bash_payload.payload))
        print "== Is a bash payload, confirmed =="

    def test_teensy_instance(self):
        tp = teensy_payload.payload()
        print "== Instantiated teensy payload =="
        self.assertTrue(isinstance(self.tp, teensy_payload.payload))
        print "== Is a teensy payload, confirmed =="

    def test_bash_properties(self):
        print "== Testing bash properties =="
        self.assertTrue(self.bp.name == "bash")

    def test_teensy_properties(self):
        print "== Testing teensy properties =="
        self.assertTrue(self.tp.name == "Teensy macOS")