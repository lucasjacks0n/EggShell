import unittest
import threading
from modules import server
from modules import multihandler

class TestMultiHandler(unittest.TestCase):
   @classmethod
   def setUpClass(self):
      print "============ Testing Multihandler ============"
   def test_multihandler_instance(self):
      server_obj = server.Server()
      multihandler_obj = multihandler.MultiHandler(server_obj)
      print "== Testing Multihandler Initialization =="
      self.assertTrue(isinstance(multihandler_obj,multihandler.MultiHandler))
      print "== Created a Multihandler =="
   def test_close_no_server(self):
      print "== Trying to close all server with no sessions =="
      server_obj = server.Server()
      multihandler_obj = multihandler.MultiHandler(server_obj)
      multihandler_obj.stop_server()
      self.assertTrue(1)
      print "== We didn't raise, success =="
   def test_background_server(self):
      print "== Testing Background Server Creation =="
      server_obj = server.Server()
      server_obj.port = 8192
      server_obj.host = "localhost"
      multihandler_obj = multihandler.MultiHandler(server_obj)
      multihandler_obj.start_background_server()
      print "== Created Background Server =="
      multihandler_obj.stop_server()
      print "== Started and Closed Successfully =="
      
