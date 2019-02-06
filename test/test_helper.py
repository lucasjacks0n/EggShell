import unittest
from modules import helper

class TestHelper(unittest.TestCase):
   def test_find_longo(self):
      string_array = ["Ya Yeet","Ya Yaboi","Ya Ytho","Ya Yoink"]
      print "============ Testing Helpers ============"
      print "== Test Longest String =="
      yoink = helper.find_longest_common_prefix(string_array)
      self.assertTrue(yoink == "Ya Y")
      print "== It is found =="
   def test_getip(self):
      print "== Testing GetIP =="
      our_ip = helper.getip()
      self.assertTrue( len(our_ip) > 0 )
   def test_b64(self):
      print "== Testing b64 =="
      bob = helper.b64("5")
      self.assertTrue(bob == "NQ==")
      print "== It do =="
   def test_error_text(self):
      helper.info_error("== I SHOULD BE RED ==")
      helper.info_warning("== I SHOULD BE YELLOW ==")
      helper.info_general("== I SHOULD BE WHITE ==")
