//
//  ZendeskFeedback.h
//  ZendeskFeedback
//
//  Created by Graham Cruse on 10/08/2012.
//  Copyright (c) 2012 Zendesk All rights reserved.
//
//  Mayor Overhaul by Daniel Eggert on 11/20/2012.
//  Copyright (c) 2012 BioWink All rights reserved.
//

#import <Foundation/Foundation.h>


@class ZendeskDropbox;



// Error codes
enum {
	ZDErrorMissingSubject =				-610001,
	ZDErrorMissingDescription =			-610002,
	ZDErrorMissingEmail =				-610003,
};

@protocol ZendeskFeedbackDelegate;




/**
    Three steps to submit a ticket to Zendesk:
 
    1.  define a key 'ZDURL' in your application's plist with your Zendesk URL as value, 
        e.g. mysite.zendesk.com.
 
    2.  instantiate the dropbox class:
        ZendeskFeedback *dropbox = [[ZendeskFeedback alloc] initWithDelegate:self];
 
    3.  Submit the request:
        [dropbox submitWithEmail:@"Email..." subject:@"Subject" andDescription:@"Description..."];
*/

@interface ZendeskFeedback : NSObject

- (id)initWithZendeskURL:(NSURL *)zendeskURL;

@property (nonatomic, weak) id<ZendeskFeedbackDelegate> delegate;
@property (readonly, nonatomic, strong) NSURL *zendeskURL;
@property (nonatomic, copy) NSString *tag;

/** Submit ticket to Zendesk server (asynchronous). */
- (void)submitWithEmail:(NSString*)email subject:(NSString*)subject description:(NSString*)description;

/** Cancel a request in progress */
- (void)cancelRequest;

@end




@protocol ZendeskFeedbackDelegate <NSObject>

@optional
// Sent when the ticket is submitted to Zendesk server successfully
- (void)submissionDidFinishLoadingForZendeskFeedback:(ZendeskFeedback *)dropbox;

// Sent when ticket submission failed
- (void)zendeskFeedback:(ZendeskFeedback *)dropbox submissionDidFailWithError:(NSError *)error;

// Sent when connected to Zendesk server
- (void)submissionConnectedToServerForZendeskFeedback:(ZendeskFeedback *)dropbox;

@end
