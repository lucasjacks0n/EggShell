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
    
    def decode(self, encodedEncrypted, BS=16):
        if self.key is None:
            raise ValueError("key is required")
        
        BS = (self.BS if self.BS else BS)
        cipher = AES.new(self.key)
        
        decrypted = cipher.decrypt(base64.b64decode(encodedEncrypted))[:BS]
        #decode 16 bytes at a time
        for i in range(1, len(base64.b64decode(encodedEncrypted)) / BS):
            cipher = AES.new(self.key, AES.MODE_CBC,
                             base64.b64decode(encodedEncrypted)[(i - 1) * BS:i * BS])
            decrypted += cipher.decrypt(base64.b64decode(encodedEncrypted)[i * BS:])[:BS]
        
        return self.pkcs7.decode(decrypted)

    #encode bytes
    def encode(self, raw, BS=16):
        if self.key is None:
            raise ValueError("key is required")
        
        BS = (self.BS if self.BS else BS)
        
        cipher = AES.new(self.key)
        encoded = self.pkcs7.encode(raw)
        encrypted = cipher.encrypt(encoded)
        return base64.b64encode(encrypted)

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


