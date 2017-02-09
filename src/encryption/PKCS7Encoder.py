#PKCS7Encoding
import binascii
from StringIO import StringIO
class PKCS7Encoder:
    def __init__(self, k=16):
        self.k = k
    
    ## @param text The padded text for which the padding is to be removed.
    # @exception ValueError Raised when the input padding is missing or corrupt.
    def decode(self, text):
        nl = len(text)
        val = int(binascii.hexlify(text[-1]), 16)
        if val > self.k:
            raise ValueError('Input is not padded or padding is corrupt')
        
        l = nl - val
        return text[:l]
    
    ## @param text The text to encode.
    def encode(self, text):
        l = len(text)
        output = StringIO()
        val = self.k - (l % self.k)
        for _ in xrange(val):
            output.write('%02x' % val)
        return text + binascii.unhexlify(output.getvalue())
