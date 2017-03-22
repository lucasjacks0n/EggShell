#ESEncryptor
#created by lucas.py
import base64

try:
    from Crypto import Random
    from Crypto.Cipher import AES
except:
    print "Make sure you have pycrypto installed\nTry running 'easy_install pycrypto'"
    exit()


#decode bytes
class ESEncryptor:
    def __init__(self, key=None, BS=None):
        self.iv = "\x00" * 16
        self.key = key
        self.BS = (BS if BS else None)
    
    def _pad(self, s):
        return s + (self.BS - len(s) % self.BS) * chr(self.BS - len(s) % self.BS)
    
    def _unpad(self, s):
        return s[:-ord(s[len(s)-1:])]

    def decrypt(self, enc):
        if len(enc) == 0:
            return ""
        enc = base64.b64decode(enc)
        cipher = AES.new(self.key, AES.MODE_CBC, self.iv)
        return self._unpad(cipher.decrypt(enc).decode('utf-8'))
    
    def encode(self, raw, BS=16):
        raw = self._pad(raw)
        cipher = AES.new(self.key, AES.MODE_CBC, self.iv)
        return base64.b64encode(cipher.encrypt(raw))
    
    def encryptString(self, string):
        return self.encode(string)
    
    #file handling
    def decryptFile(self, fileinname, fileoutname, fileSize,password=0):
        password = self.key if password == 0 else password
        aes = AES.new(password, AES.MODE_CBC, self.iv)
        in_file = open(fileinname,"rb")
        encryptedData = in_file.read()
        #trim
        offset = len(encryptedData) - fileSize
        encryptedData = encryptedData[offset:]
        in_file.close()
        
        #decrypt,get length
        decryptedData = self._unpad(aes.decrypt(encryptedData))
        
        #write data subtracting the offset
        out_file = open(fileoutname,'a+b')
        out_file.write(decryptedData)
        out_file.close()
        return True


