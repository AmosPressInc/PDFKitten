/*
 *	Given a keyword and a stream of charachers, triggers when
 *	the desired needle is found.
 *
 *	The implementation ressembles a finite state machine (FSM).
 *
 *
 */

#import <Foundation/Foundation.h>
#import "MHPDFFont.h"

@class MHPDFStringDetector;

@protocol StringDetectorDelegate <NSObject>

@optional

/* Tells the delegate that the first character of the needle was detected */
- (void)detector:(MHPDFStringDetector *)detector didStartMatchingString:(NSString *)string;

/* Tells the delegate that the entire needle was detected */
- (void)detector:(MHPDFStringDetector *)detector foundString:(NSString *)needle;

/* Tells the delegate that one character was scanned */
- (void)detector:(MHPDFStringDetector *)detector didScanCharacter:(unichar)character;

@end


@interface MHPDFStringDetector : NSObject {
	NSString *keyword;
	NSUInteger keywordPosition;
	NSMutableString *unicodeContent;
	id<StringDetectorDelegate> delegate;
  BOOL isCancelled;
}

/* Initialize with a given needle */
- (id)initWithKeyword:(NSString *)needle;

/* Feed more charachers into the state machine */
- (NSString *)appendPDFString:(CGPDFStringRef)string withFont:(MHPDFFont *)font;

/* Reset the detector state */
- (void)reset;

- (void)cancel;

@property (nonatomic, retain) NSString *keyword;
@property (nonatomic, assign) id<StringDetectorDelegate> delegate;
@property (nonatomic, readonly) NSString *unicodeContent;
@end
