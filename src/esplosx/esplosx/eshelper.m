//
//  eshelper.m
//  esplosx
//
//  Created by Lucas Jackson on 3/13/17.
//  Copyright © 2017 lucas.py. All rights reserved.
//

#import "eshelper.h"

@implementation eshelper

+(NSDictionary *)stringToJSON:(NSString*)inputstr :(NSError*)error {
    return [NSJSONSerialization JSONObjectWithData: [inputstr dataUsingEncoding:NSUTF8StringEncoding]
                                           options: NSJSONReadingAllowFragments
                                             error: &error];
}

+(NSString *)reverseString:(NSString *)str {
    NSMutableString *reversed = [NSMutableString string];
    NSInteger charIndex = [str length];
    while (charIndex > 0) {
        charIndex--;
        NSRange subRange = NSMakeRange(charIndex, 1);
        [reversed appendString:[str substringWithRange:subRange]];
    }
    return reversed;
}

+(NSString *)forgetFirst:(NSArray *)args {
    int x = 1;
    NSString *path = @"";
    for (NSString *tpath in args) {
        if (x != 1) {
            path = [NSString stringWithFormat:@"%@%@ ",path,tpath];
        }
        x++;
    }
    return [path substringToIndex:[path length] - 1];
}

@end
