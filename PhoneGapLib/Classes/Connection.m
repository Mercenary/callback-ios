/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc.
 */


#import "Connection.h"
#import "PGReachability.h"

@interface PGConnection(PrivateMethods)
- (void) updateOnlineStatus;
@end

@implementation PGConnection

@synthesize connectionType, internetReach;

- (NSString*) w3cConnectionTypeFor:(PGReachability*)reachability
{
	NetworkStatus networkStatus = [reachability currentReachabilityStatus];
	switch(networkStatus)
	{
        case NotReachable:
			return @"unknown";
        case ReachableViaWWAN:
			return @"2g"; // no generic default, so we use the lowest common denominator
        case ReachableViaWiFi:
			return @"wifi";
		default:
			return @"none";
    }
}

- (BOOL) isCellularConnection:(NSString*)theConnectionType
{
	return	[theConnectionType isEqualToString:@"2g"] ||
			[theConnectionType isEqualToString:@"3g"] ||
			[theConnectionType isEqualToString:@"4g"];
}

- (void) updateReachability:(PGReachability*)reachability
{
	if (reachability) {
		self.connectionType = [self w3cConnectionTypeFor:reachability];
	}
	
	NSString* js = nil;
	// write the connection type
	js = [NSString stringWithFormat:@"navigator.network.connection.type = '%@';", self.connectionType];
	[super writeJavascript:js];
	
	// send "online"/"offline" event
	[self updateOnlineStatus];
}

- (void) updateConnectionType:(NSNotification*)note
{
	PGReachability* curReach = [note object];

	if (curReach != nil && [curReach isKindOfClass:[PGReachability class]])
	{
		[self updateReachability:curReach];
	}
}

- (void) updateOnlineStatus
{
	// send "online"/"offline" event
	NetworkStatus status = [self.internetReach currentReachabilityStatus];
	BOOL online = (status == ReachableViaWiFi) || (status == ReachableViaWWAN);
	if (online) {
		[super writeJavascript:@"PhoneGap.fireDocumentEvent('online');"];
	} else {
		[super writeJavascript:@"PhoneGap.fireDocumentEvent('offline');"];
	}
}

- (void) prepare
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionType:) 
												 name:kReachabilityChangedNotification object:nil];
	
	self.internetReach = [PGReachability reachabilityForInternetConnection];
	[self.internetReach startNotifier];
	self.connectionType = [self w3cConnectionTypeFor:self.internetReach];
	
	[self performSelector:@selector(updateOnlineStatus) withObject:nil afterDelay:1.0];
}

- (void) onPause 
{
	[self.internetReach stopNotifier];
}

- (void) onResume 
{
    [self.internetReach startNotifier];
    [self updateReachability:self.internetReach];
}

- (PGPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (PGConnection*)[super initWithWebView:theWebView];
    if (self) {
        self.connectionType = @"none";
        [self prepare];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPause) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResume) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
	self.internetReach = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:kReachabilityChangedNotification object:nil];

    [super dealloc];
}

@end
