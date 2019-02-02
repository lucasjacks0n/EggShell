import unittest
import sys

if __name__ == "__main__":
   tests = unittest.TestLoader().discover('./test/')
   unittest.TextTestRunner().run( tests )
