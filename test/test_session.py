import os
import pwn
import sys
import unittest

class TestSession(unittest.TestCase):
    def setUp(self):
        # disable pwntools log
        pwn.context.log_level = 'critical'

        # setup a session with the vagrant vm
        self.eggshell_proc = pwn.process(["python", "eggshell.py"])

        # Make a bash payload
        self.eggshell_proc.sendline("3")
        self.eggshell_proc.sendline("1")

        # Default IP/port
        self.eggshell_proc.sendline("")
        self.eggshell_proc.sendline("")

        # Yes server, no multi
        self.eggshell_proc.sendline("y")
        self.eggshell_proc.sendline("n")

        # Parse payload
        self.eggshell_proc.recvuntil("LPORT = ")
        self.eggshell_proc.recvuntil("----------------------------------------")
        self.eggshell_proc.recvline()
        payload = self.eggshell_proc.recvline()[7:-5]
        # print "eggshell payload: {}".format(repr(payload))

        # Run payload
        # https://stackoverflow.com/a/28293101
        with open("run_payload.sh", "w") as f:
            f.write("""#!/usr/bin/expect
set timeout 20
set cmd [lrange $argv 1 end]
set password [lrange $argv 0 0]
eval spawn $cmd
expect "assword:"
send "$password\r";
interact
""")
        os.system("chmod +x run_payload.sh")
        os.system("./run_payload.sh vagrant ssh vagrant@127.0.0.1 -p2222 -o \"StrictHostKeyChecking no\" -C '{}'".format(payload))

        # Reset stdin
        # print self.eggshell_proc.recvall(timeout=2)
        # print self.eggshell_proc.recvuntil("ubuntu-xenial:/home/vagrant vagrant> ")

    def tearDown(self):
        self.eggshell_proc.kill()
        os.system("rm -f run_payload.sh")

    def test_pid(self):
        # get payload pid from vagrant
        vagrant_pid = int(run_shell_command("ps -ef | grep python | grep -v grep | awk '{print $2 }'"))

        # get eggshell pid
        self.eggshell_proc.sendline("pid")
        self.eggshell_proc.recvuntil("Connection...\n")
        eggshell_pid = int(self.eggshell_proc.recvline().split(" ")[2][4:].strip())

        print "== Checking PID =="
        self.assertTrue(vagrant_pid == eggshell_pid)
        print "== PIDs Match =="

    def test_pwd(self):
        # get login pwd from vagrant
        vagrant_pwd = run_shell_command("pwd")

        # get eggshell pid
        self.eggshell_proc.sendline("pwd")
        self.eggshell_proc.recvuntil("Connection...\n")
        eggshell_pwd = self.eggshell_proc.recvline().split(" ")[2][4:].strip()

        print "== Checking PWD =="
        self.assertTrue(vagrant_pwd == eggshell_pwd)
        print "== PWDs Match =="

def run_shell_command(command, timeout=0.5):
    p = pwn.process(["./run_payload.sh", "vagrant", "ssh", "vagrant@127.0.0.1", "-p2222", "-o", "StrictHostKeyChecking no", "-C", command])
    p.recvuntil("password:")
    p.recvline()
    return p.recvall(timeout=timeout).strip()