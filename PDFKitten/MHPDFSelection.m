#import "MHPDFSelection.h"
#import "MHPDFRenderingState.h"


@implementation MHPDFSelection
@synthesize frame, transform, pageNumber = _pageNumber;
@synthesize textAroundSearch = _textAroundSearch;

- (NSString*) description {
    return [NSString stringWithFormat:@"%@: <%p> — %d — '%@'", NSStringFromClass([self class]), self, _pageNumber, _textAroundSearch];
}

/* Rendering state represents opening (left) cap */
- (id)initWithStartState:(MHPDFRenderingState *)state
{
	if ((self = [super init]))
	{
		initialState = [state copy];
	}
	return self;
}

/* Rendering state represents closing (right) cap */
- (void)finalizeWithState:(MHPDFRenderingState *)state
{
	// Concatenate CTM onto text matrix
	transform = CGAffineTransformConcat([initialState textMatrix], [initialState ctm]);

	MHPDFFont *openingFont = [initialState font];
	MHPDFFont *closingFont = [state font];
	
	// Width (difference between caps) with text transformation removed
	CGFloat width = [state textMatrix].tx - [initialState textMatrix].tx;	
	width /= [state textMatrix].a;

	// Use tallest cap for entire selection
	CGFloat startHeight = [openingFont maxY] - [openingFont minY];
	CGFloat finishHeight = [closingFont maxY] - [closingFont minY];
	MHPDFRenderingState *s = (startHeight > finishHeight) ? initialState : state;

	MHPDFFont *font = [s font];
	MHPDFFontDescriptor *descriptor = [font fontDescriptor];
	
	// Height is ascent plus (negative) descent
	CGFloat height = [s convertToUserSpace:(font.maxY - font.minY)];

	// Descent
	CGFloat descent = [s convertToUserSpace:descriptor.descent];

	// Selection frame in text space
	frame = CGRectMake(0, descent, width, height);
	
//	[initialState release]; initialState = nil;
}


#pragma mark - Memory Management

- (void)dealloc
{
	[initialState release];
    [_textAroundSearch release];
	[super dealloc];
}

@end
