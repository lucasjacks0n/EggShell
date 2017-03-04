#ESEncryptor
#created by lucas.py
import base64
from PKCS7Encoder import PKCS7Encoder

try:
    from Crypto import Random
    from Crypto.Cipher import AES
except:
    print "Make sure you have pycrypto installed\nTry running 'easy_install pycrypto'"
    exit()


#decode bytes
class ESEncryptor:
    def __init__(self, key=None, BS=None):
        self.key = key
        self.pkcs7 = PKCS7Encoder()
        self.BS = (BS if BS else None)
    
    def _pad(self, s):
        return s + (self.BS - len(s) % self.BS) * chr(self.BS - len(s) % self.BS)
    
    def _unpad(self, s):
        return s[:-ord(s[len(s)-1:])]

    def decrypt(self, enc):
        enc = base64.b64decode(enc)
        iv = "\x00" * 16
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return self._unpad(cipher.decrypt(enc).decode('utf-8'))
    
    def encode(self, raw, BS=16):
        raw = self._pad(raw)
        iv = "\x00" * 16
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return base64.b64encode(cipher.encrypt(raw))
    
    #file handling
    def decryptFile(self, filein, fileout, password, fileSize, key_length=16):

        iv = "\x00" * 16
        aes = AES.new(password, AES.MODE_CBC, iv)
        
        #encodepadding
        in_file = open(filein,"rb")
        encryptedData = in_file.read()
        pad_text = self.pkcs7.encode(encryptedData)
        in_file.close()
        
        #decrypt,get length
        decryptedData = aes.decrypt(pad_text)
        dataSize = len(decryptedData)
        
        offset = dataSize - fileSize
        
        if offset < 0:
            return False
        
        #write data subtracting the offset
        out_file = open(fileout,'a+b')
        out_file.write(decryptedData[:-offset])
        out_file.close()
        return True


