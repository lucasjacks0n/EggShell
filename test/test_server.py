import unittest
from modules import server

class TestServer(unittest.TestCase):
   @classmethod
   def setUpClass(self):
      print "============ Testing Server ============"
   def test_server_instance(self):
      server_obj = server.Server()
      print "== Instantiated Server =="
      self.assertTrue(isinstance(server_obj,server.Server))
      print "== Is a server, confirmed =="
   def test_server_modules(self):
      server1 = server.Server()
      modules = server1.modules_universal
      print "== Instantiated Server =="
      self.assertTrue(len(modules))
      print "== Loaded Modules successfully =="
   def test_get_modules(self):
      server_obj = server.Server()
      print "== Instantiated Server =="
      modules_macos = server_obj.get_modules("macos")
      modules_ios = server_obj.get_modules("iOS")
      print "== Checking if not empty and share universals =="
      self.assertTrue(any(k in modules_ios for k in modules_macos))
   def test_modules_universal(self):
      server_obj = server.Server()
      print "== Instantiated Server =="
      self.assertRaises(server_obj.get_modules(""))
      print "== This code is broken =="
