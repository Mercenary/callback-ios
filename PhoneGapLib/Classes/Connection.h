/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 */

#import <Foundation/Foundation.h>
#import "PGPlugin.h"
#import "PGReachability.h"


@interface PGConnection : PGPlugin {
	NSString* type;
	
	PGReachability* internetReach;
}

@property (copy) NSString* connectionType;
@property (retain) PGReachability* internetReach;

@end
