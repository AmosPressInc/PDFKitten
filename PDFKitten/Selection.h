#import <Foundation/Foundation.h>

@class RenderingState;

@interface Selection : NSObject {
	RenderingState *initialState;
	CGAffineTransform transform;
	CGRect frame;
}

/* Initalize with rendering state (starting marker) */
- (id)initWithStartState:(RenderingState *)state;

/* Finalize the selection (ending marker) */
- (void)finalizeWithState:(RenderingState *)state;

/* The frame with zero origin covering the selection */
@property (nonatomic, readonly) CGRect frame;

/* The page number which host the selection */
@property (nonatomic, assign) NSUInteger pageNumber;

/* The transformation needed to position the selection */
@property (nonatomic, readonly) CGAffineTransform transform;

/* The text around the search */
@property (nonatomic, retain) NSString *textAroundSearch;

@end
