//
//  escryptor.m
//  Eggshell OSX Payload
//
//  Created by Lucas Jackson on 2/26/17.
//  Copyright © 2017 Lucas Jackson. All rights reserved.
//

#import "escryptor.h"
#import "b64.h"
#include <openssl/aes.h>

@implementation escryptor

extern int OPENSSL_cleanse(void *ptr, size_t len);

+(NSData *)encryptNSData:(NSString*)key :(NSData*)data {
    //add padding
    int padlen = AES_BLOCK_SIZE - (data.length % AES_BLOCK_SIZE);
    NSMutableData *paddedData = [[NSMutableData data] initWithData:data];
    for (int i = 0; i < padlen; i++) {
        char bytesToAppend[1] = {(char)padlen};
        [paddedData appendBytes:bytesToAppend length:1];
    }
    const unsigned char* aeskey = (const unsigned char*)[key cStringUsingEncoding:NSASCIIStringEncoding];
    OPENSSL_cleanse(NULL, 0);
    /* Initialization vector */
    unsigned char iv[AES_BLOCK_SIZE];
    //outputbuffer
    unsigned char *output = (unsigned char *)malloc(data.length * sizeof(char));
    /* AES-128 bit CBC Encryption */
    AES_KEY enc_key;
    //encrypt
    memset(iv, 0, AES_BLOCK_SIZE);
    AES_set_encrypt_key(aeskey, (int)strlen((const char*)aeskey) * 8, &enc_key);
    //input, output, inputlength, key, iv, operation
    AES_cbc_encrypt([paddedData bytes], output, paddedData.length, &enc_key, iv, AES_ENCRYPT);
    NSData *finalData = [NSData dataWithBytes:output length:paddedData.length];
    (void)realloc(output,0);
    return finalData;
}

+(NSData *)decryptNSData:(NSString*)key :(NSData*)data {
    //work around to find length, strlen won't count size after \0
    //init args
    const unsigned char* aeskey = (const unsigned char*)[key cStringUsingEncoding:NSASCIIStringEncoding];
    //cleanse your soul
    OPENSSL_cleanse(NULL, 0);
    /* Initialization vector */
    unsigned char iv[AES_BLOCK_SIZE];
    //outputbuffer
    unsigned char *output = (unsigned char *)malloc(data.length * sizeof(char));
    /* AES-128 bit CBC Encryption */
    memset(iv, 0, AES_BLOCK_SIZE);
    AES_KEY dec_key;
    //decrypt
    AES_set_decrypt_key(aeskey, (int)strlen((const char*)aeskey) * 8, &dec_key);
    //DECRYPT! input, output, inputlength, key, iv, operation
    AES_cbc_encrypt([data bytes], output, data.length, &dec_key, iv, AES_DECRYPT);
    //const char to nsdata, substring from our blocksize total
    //NSData *outputData;
    //remove padding, detect if last byte is a padding byte
    int padnum = (char)output[(int)data.length - 1];
    //if nothing to unpad
    if (padnum > 16) {
        padnum = 0;
    }
    //complete
    NSData *finalData = [NSData dataWithBytes:output length:(int)data.length - padnum];
    (void)realloc(output, 0);
    return finalData;
}



+(NSString *)encryptNSStringToB64:(NSString*)key :(NSString*)data {
    //add padding
    int padlen = AES_BLOCK_SIZE - (data.length % AES_BLOCK_SIZE);
    for (int i = 0; i < padlen; i++) {
        data = [NSString stringWithFormat:@"%@%c",data,(char)padlen]; //need right formatting
    }
    const unsigned char* inputdata = (const unsigned char*)[data cStringUsingEncoding:NSASCIIStringEncoding];
    const unsigned char* aeskey = (const unsigned char*)[key cStringUsingEncoding:NSASCIIStringEncoding];
    OPENSSL_cleanse(NULL, 0);
    /* Initialization vector */
    unsigned char iv[AES_BLOCK_SIZE];
    //outputbuffer
    unsigned char output[strlen((const char*)inputdata)];
    /* AES-128 bit CBC Encryption */
    AES_KEY enc_key;
    //encrypt
    memset(iv, 0, AES_BLOCK_SIZE);
    AES_set_encrypt_key(aeskey, (int)strlen((const char*)aeskey) * 8, &enc_key);
    //input, output, inputlength, key, iv, operation
    AES_cbc_encrypt(inputdata, output, strlen((const char*)inputdata), &enc_key, iv, AES_ENCRYPT);
    //decrypt
    return [NSString stringWithFormat:@"%s",b64_encode(output, strlen((const char*)inputdata))];
}

+(NSString *)decryptB64ToNSString:(NSString*)key :(NSString*)data {
    //work around to find length, strlen won't count size after \0
    size_t outputlen = [[NSData alloc] initWithBase64EncodedString:data options:0].length;
    //init args
    const unsigned char* inputdata = b64_decode([data cStringUsingEncoding:NSASCIIStringEncoding],data.length);
    const unsigned char* aeskey = (const unsigned char*)[key cStringUsingEncoding:NSASCIIStringEncoding];
    //cleanse your soul
    OPENSSL_cleanse(NULL, 0);
    /* Initialization vector */
    unsigned char iv[AES_BLOCK_SIZE];
    //outputbuffer
    unsigned char output[outputlen];
    /* AES-128 bit CBC Encryption */
    memset(iv, 0, AES_BLOCK_SIZE);
    AES_KEY dec_key;
    //decrypt
    AES_set_decrypt_key(aeskey, (int)strlen((const char*)aeskey) * 8, &dec_key);
    //DECRYPT! input, output, inputlength, key, iv, operation
    AES_cbc_encrypt(inputdata, output, outputlen, &dec_key, iv, AES_DECRYPT);
    //const char to nsstring, substring from our blocksize total
    NSString *outputString = [[NSString stringWithCString:(const char *)output encoding:NSASCIIStringEncoding] substringToIndex:outputlen];
    //remove padding, detect if last byte is a padding byte
    int padnum = (char)output[(int)outputlen - 1];
    if (padnum <= 16) {
        //trim
        outputString = [outputString substringToIndex:outputString.length - padnum];
    }
    //complete
    return outputString;
}
@end
