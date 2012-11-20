//
//  ZendeskFeedback.m
//  ZendeskFeedback
//
//  Created by Graham Cruse on 10/08/2012.
//  Copyright (c) 2012 Zendesk All rights reserved.
//
//  Mayor Overhaul by Daniel Eggert on 11/20/2012.
//  Copyright (c) 2012 BioWink All rights reserved.
//

#import "ZendeskFeedback.h"


static NSString * const ZendeskFeedbackDescription = @"description";
static NSString * const ZendeskFeedbackEmail = @"email";
static NSString * const ZendeskFeedbackSubject = @"subject";
static NSString * const ZendeskURLDoesNotExistException = @"ZDURLDoesNotExist";


@implementation ZendeskFeedback
{
	NSMutableData *_receivedData;
    NSURLConnection *_connection;
}

- (id)init
{
    return nil;
}

- (id)initWithZendeskURL:(NSURL *)zendeskURL;
{
	self = [super init];
    if (self) {
        _zendeskURL = zendeskURL;
        
        if (_zendeskURL == nil) {
            @throw [NSException exceptionWithName:ZendeskURLDoesNotExistException reason:@"ZDURL is not set in Info.plist file" userInfo:nil];
        }
        self.tag = @"dropbox";
    }
	return self;
}

#pragma mark request control

- (void)submitWithEmail:(NSString*)email subject:(NSString*)subject description:(NSString*)description
{
    NSURL *url = [NSURL URLWithString:@"requests/mobile_api/create" relativeToURL:self.zendeskURL];
    
    // Configure request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:MAXFLOAT];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"1.0" forHTTPHeaderField:@"X-Zendesk-Mobile-API"];
    
    // Add form body
	NSMutableString *body = [[NSMutableString alloc] init];
	if (self.tag != nil) {
		[body appendString:@"set_tags="];
		[body appendString:self.tag];
	}
    if (email != nil) {
		[body appendString:@"&"];
        [body appendString:ZendeskFeedbackEmail];
        [body appendString:@"="];
        [body appendString:email];
    }
    if (subject != nil) {
		[body appendString:@"&"];
        [body appendString:ZendeskFeedbackSubject];
        [body appendString:@"="];
        [body appendString:subject];
    }
    if (description != nil) {
		[body appendString:@"&"];
        [body appendString:ZendeskFeedbackDescription];
        [body appendString:@"="];
        [body appendString:description];
    }
    [body appendString:@"&via_id=17"];
    [body appendString:@"&commit="];
    
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
	// Start the request
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (_connection == nil) {
        if ([self.delegate respondsToSelector:@selector(zendeskFeedback:submissionDidFailWithError:)]) {
            [self.delegate zendeskFeedback:self submissionDidFailWithError:nil];
        }
    } else {
		// Create the NSMutableData that will hold the received data
		_receivedData = [[NSMutableData alloc] initWithCapacity:250];
	}
}

- (void)cancelRequest
{
    [_connection cancel];
    _connection = nil;
    _receivedData = nil;
}


#pragma mark connection callbacks

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response
{
    [_receivedData setLength:0]; // prepare for data
	if ( [self.delegate respondsToSelector:@selector(submissionConnectedToServerForZendeskFeedback:)] ) {
		[self.delegate submissionConnectedToServerForZendeskFeedback:self];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(zendeskFeedback:submissionDidFailWithError:)]) {
        [self.delegate zendeskFeedback:self submissionDidFailWithError:error];
    }
    _connection = nil;
    _receivedData = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:&error];
	if ((dict == nil) || (![dict isKindOfClass:[NSDictionary class]])) {
        if ([self.delegate respondsToSelector:@selector(zendeskFeedback:submissionDidFailWithError:)]) {
            [self.delegate zendeskFeedback:self submissionDidFailWithError:error];
        }
        return;
    }
    
	NSString *msg = dict[@"error"];
	if (msg) {
		NSRange myrange;
		myrange = [msg rangeOfString:@"subject"];
		if ( myrange.location != NSNotFound ) {
			error = [NSError errorWithDomain:NSCocoaErrorDomain code:ZDErrorMissingSubject userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
		}
		myrange = [msg rangeOfString:@"description"];
		if ( myrange.location != NSNotFound ) {
			error = [NSError errorWithDomain:NSCocoaErrorDomain code:ZDErrorMissingDescription userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
		}
		myrange = [msg rangeOfString:@"email"];
		if ( myrange.location != NSNotFound ) {
			error = [NSError errorWithDomain:NSCocoaErrorDomain code:ZDErrorMissingEmail userInfo:[NSDictionary dictionaryWithObjectsAndKeys:msg, NSLocalizedDescriptionKey, nil]];
		}
        if ([self.delegate respondsToSelector:@selector(zendeskFeedback:submissionDidFailWithError:)]) {
            [self.delegate zendeskFeedback:self submissionDidFailWithError:error];
		}
	} else {
		if ([self.delegate respondsToSelector:@selector(submissionDidFinishLoadingForZendeskFeedback:)] ) {
			[self.delegate submissionDidFinishLoadingForZendeskFeedback:self];
		}
	}
    _connection = nil;
    _receivedData = nil;
}


#pragma mark misc

- (NSString *)encodeStringForPost:(NSString*)string
{
    if (string) {
        CFStringRef s = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL,
                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]-",
                                                                kCFStringEncodingUTF8 );
        return CFBridgingRelease(s);
    }
    return @"";
}

@end
