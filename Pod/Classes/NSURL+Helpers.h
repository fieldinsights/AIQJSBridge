//
//  NSURL+Helpers.h
//  AIQ
//
//  Created by Marcin Lukow on 2/2/12.
//  Copyright (c) 2012 Appear Networks Systems AB. All rights reserved.
//

@interface NSURL (Helpers)

/*!
 @method queryAsDictionary
 
 @abstract returns query string as dictionary.
 @discussion This method can be used to retrieve the query string
 represented as a immutable dictionary.
 
 @return immutable dictionary containing the query parameters, will
 not be nil
 */
- (NSDictionary *)queryAsDictionary;

@end
