import unittest
from modules.payloads import bash_payload, teensy_payload
import os
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

    def test_teensy_generation(self):
        # default lhost/lport
        self.eggshell_proc.sendline("")
        self.eggshell_proc.sendline("")

        # no persistence (default)
        self.eggshell_proc.sendline("")

        # get filepath
        self.eggshell_proc.recvuntil("Payload saved to ")
        payload = self.eggshell_proc.recvline().strip()

        print "== Testing teensy payload generation =="
        self.assertTrue(os.path.isfile(payload))
        print "== Payload good =="
    
    def test_teensy_bad_port(self):
        # default lhost
        self.eggshell_proc.sendline("")

        # invalid port (has to be >=1024)
        self.eggshell_proc.sendline("42")

        out = self.eggshell_proc.recvall(timeout=0.5)
        expected = "invalid port, please enter a value >= 1024"

        print "== Testing reprompt for payload port =="
        self.assertTrue(expected in out)
        print "== Reprompt for port good =="