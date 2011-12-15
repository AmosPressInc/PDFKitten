#import <Foundation/Foundation.h>

@class MHPDFRenderingState;

@interface MHPDFSelection : NSObject {
	MHPDFRenderingState *initialState;
	CGAffineTransform transform;
	CGRect frame;
}

/* Initalize with rendering state (starting marker) */
- (id)initWithStartState:(MHPDFRenderingState *)state;

/* Finalize the selection (ending marker) */
- (void)finalizeWithState:(MHPDFRenderingState *)state;

/* The frame with zero origin covering the selection */
@property (nonatomic, readonly) CGRect frame;

/* The page number which host the selection */
@property (nonatomic, assign) NSUInteger pageNumber;

/* The transformation needed to position the selection */
@property (nonatomic, readonly) CGAffineTransform transform;

/* The text around the search */
@property (nonatomic, retain) NSString *textAroundSearch;

@end
