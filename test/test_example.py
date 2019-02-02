import unittest
from modules import server

class TestExample(unittest.TestCase):
   def test_server_instance(self):
      server_obj = server.Server()
      print "== Instantiated Server =="
      self.assertTrue(isinstance(server_obj,server.Server))
      print "== Is a server, confirmed =="
   
