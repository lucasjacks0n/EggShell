import os
import sys
import unittest

def vagrant_up():
    #os.system("vagrant destroy -f")
    if os.system("vagrant up") != 0:
        print "error starting vagrant, exiting"
        return False
    return True

def main():
    if not vagrant_up():
        return 1

    tests = unittest.TestLoader().discover('./test/')
    unittest.TextTestRunner().run( tests )

    return 0

if __name__ == "__main__":
    sys.exit(main())