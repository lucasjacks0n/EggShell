import hashlib
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

        # get eggshell pwd
        self.eggshell_proc.sendline("pwd")
        self.eggshell_proc.recvuntil("Connection...\n")
        eggshell_pwd = self.eggshell_proc.recvline().split(" ")[2][4:].strip()

        print "== Checking PWD =="
        self.assertTrue(vagrant_pwd == eggshell_pwd)
        print "== PWDs Match =="

    def test_upload(self):
        # remove file it it already exists on the remote (see issue #11)
        run_shell_command("rm -f file1")

        # upload file
        self.eggshell_proc.sendline("upload test/victim_files/file1")

        # get hash of local file
        local_hash = hashlib.sha1(open("test/victim_files/file1").read()).hexdigest()

        # get hash of remote file
        remote_hash = run_shell_command("shasum file1").split(" ")[0]

        print "== Checking file upload =="
        self.assertTrue(local_hash == remote_hash)
        print "== Uploaded file is good =="

    def test_download(self):
        # remove downloaded file
        os.system("rm -f downloads/file2")

        # download file
        self.eggshell_proc.sendline("download my_files/file2")
        # without this recvall call, the file doesn't actually get downloaded
        # i haven't a clue why, probably something to do with an i/o lock blocking the download?
        self.eggshell_proc.recvall(timeout=1)

        # get hash of downloaded file
        local_hash = hashlib.sha1(open("downloads/file2").read()).hexdigest()

        # get hash of remote origin file
        remote_hash = run_shell_command("shasum my_files/file2").split(" ")[0]
        
        print "== Checking file download =="
        self.assertTrue(local_hash == remote_hash)
        print "== Downloaded file is good =="

def run_shell_command(command, timeout=0.5):
    p = pwn.process(["./run_payload.sh", "vagrant", "ssh", "vagrant@127.0.0.1", "-p2222", "-o", "StrictHostKeyChecking no", "-C", command])
    p.recvuntil("password:")
    p.recvline()
    return p.recvall(timeout=timeout).strip()