//
//  eshelper.h
//  esplosx
//
//  Created by Lucas Jackson on 3/13/17.
//  Copyright © 2017 lucas.py. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface eshelper : NSObject

+(NSDictionary *)stringToJSON:(NSString*)inputstr :(NSError*)error;
+(NSString *)reverseString:(NSString *)str;
+(NSString *)forgetFirst:(NSArray *)args;

@end
