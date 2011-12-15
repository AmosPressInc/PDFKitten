#import "MHPDFScanner.h"

#pragma mark 

@interface MHPDFScanner ()

#pragma mark - Text showing

// Text-showing operators
void Tj(CGPDFScannerRef scanner, void *info);
void quot(CGPDFScannerRef scanner, void *info);
void doubleQuot(CGPDFScannerRef scanner, void *info);
void TJ(CGPDFScannerRef scanner, void *info);

#pragma mark Text positioning

// Text-positioning operators
void Td(CGPDFScannerRef scanner, void *info);
void TD(CGPDFScannerRef scanner, void *info);
void Tm(CGPDFScannerRef scanner, void *info);
void TStar(CGPDFScannerRef scanner, void *info);

#pragma mark Text state

// Text state operators
void BT(CGPDFScannerRef scanner, void *info);
void Tc(CGPDFScannerRef scanner, void *info);
void Tw(CGPDFScannerRef scanner, void *info);
void Tz(CGPDFScannerRef scanner, void *info);
void TL(CGPDFScannerRef scanner, void *info);
void Tf(CGPDFScannerRef scanner, void *info);
void Ts(CGPDFScannerRef scanner, void *info);

#pragma mark Graphics state

// Special graphics state operators
void q(CGPDFScannerRef scanner, void *info);
void Q(CGPDFScannerRef scanner, void *info);
void cm(CGPDFScannerRef scanner, void *info);

- (void) callDelegateOnMainThread: (SEL) selector withArg: (id) arg secondArg: (id) secondArg;

@property (nonatomic, retain) MHPDFSelection *currentSelection;
@property (nonatomic, readonly) MHPDFRenderingState *currentRenderingState;
@property (nonatomic, readonly) MHPDFFont *currentFont;
@property (nonatomic, readonly) CGPDFDocumentRef pdfDocument;
@property (nonatomic, copy) NSURL *documentURL;

/* Returts the operator callbacks table for scanning page stream */
@property (nonatomic, readonly) CGPDFOperatorTableRef operatorTable;

@end

#pragma mark

@implementation MHPDFScanner

#pragma mark - Initialization

- (id)initWithDocument:(CGPDFDocumentRef)document
{
	if ((self = [super init]))
	{
		pdfDocument = CGPDFDocumentRetain(document);
        _numberOfPages = (NSUInteger)CGPDFDocumentGetNumberOfPages(pdfDocument);
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
	if ((self = [super init]))
	{
		self.documentURL = [NSURL fileURLWithPath:path];
	}
	return self;
}

#pragma mark Scanner state accessors

- (MHPDFRenderingState *)currentRenderingState
{
	return [self.renderingStateStack topRenderingState];
}

- (MHPDFFont *)currentFont
{
	return self.currentRenderingState.font;
}

- (CGPDFDocumentRef)pdfDocument
{
	if (!pdfDocument)
	{
		pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)self.documentURL);
	}
    _numberOfPages = (NSUInteger)CGPDFDocumentGetNumberOfPages(pdfDocument);
	return pdfDocument;
}

/* The operator table used for scanning PDF pages */
- (CGPDFOperatorTableRef)operatorTable
{
	if (operatorTable)
	{
		return operatorTable;
	}
	
	operatorTable = CGPDFOperatorTableCreate();

	// Text-showing operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tj", Tj);
	CGPDFOperatorTableSetCallback(operatorTable, "\'", quot);
	CGPDFOperatorTableSetCallback(operatorTable, "\"", doubleQuot);
	CGPDFOperatorTableSetCallback(operatorTable, "TJ", TJ);
	
	// Text-positioning operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tm", Tm);
	CGPDFOperatorTableSetCallback(operatorTable, "Td", Td);		
	CGPDFOperatorTableSetCallback(operatorTable, "TD", TD);
	CGPDFOperatorTableSetCallback(operatorTable, "T*", TStar);
	
	// Text state operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tw", Tw);
	CGPDFOperatorTableSetCallback(operatorTable, "Tc", Tc);
	CGPDFOperatorTableSetCallback(operatorTable, "TL", TL);
	CGPDFOperatorTableSetCallback(operatorTable, "Tz", Tz);
	CGPDFOperatorTableSetCallback(operatorTable, "Ts", Ts);
	CGPDFOperatorTableSetCallback(operatorTable, "Tf", Tf);
	
	// Graphics state operators
	CGPDFOperatorTableSetCallback(operatorTable, "cm", cm);
	CGPDFOperatorTableSetCallback(operatorTable, "q", q);
	CGPDFOperatorTableSetCallback(operatorTable, "Q", Q);
	
	CGPDFOperatorTableSetCallback(operatorTable, "BT", BT);
	
	return operatorTable;
}

/* Create a font dictionary given a PDF page */
- (MHPDFFontCollection *)fontCollectionWithPage:(CGPDFPageRef)page
{
	CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page);
	if (!dict)
	{
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing");
		return nil;
	}
	CGPDFDictionaryRef resources;
	if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
	{
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing Resources dictionary");
		return nil;	
	}
	CGPDFDictionaryRef fonts;
	if (!CGPDFDictionaryGetDictionary(resources, "Font", &fonts)) return nil;
	MHPDFFontCollection *collection = [[MHPDFFontCollection alloc] initWithFontDictionary:fonts];
	return [collection autorelease];
}

/* Scan the given page of the current document */
- (void)scanDocumentPage:(NSUInteger)pageNumber
{
	CGPDFPageRef page = CGPDFDocumentGetPage(self.pdfDocument, pageNumber);
    [self scanPage:page];
}

#pragma mark Start scanning

- (void)scanPage:(CGPDFPageRef)page
{
	// Return immediately if no keyword set
	if (!keyword) return;
    
    NSUInteger pageNumber = (NSUInteger)CGPDFPageGetPageNumber(page);
    _initialPage = pageNumber;
    _currentPage = pageNumber;
    
    [self.stringDetector reset];
    self.stringDetector.keyword = self.keyword;

    // Initialize font collection (per page)
	self.fontCollection = [self fontCollectionWithPage:page];
    
	CGPDFContentStreamRef content = CGPDFContentStreamCreateWithPage(page);
	CGPDFScannerRef scanner = CGPDFScannerCreate(content, self.operatorTable, self);
	CGPDFScannerScan(scanner);
	CGPDFScannerRelease(scanner); scanner = nil;
	CGPDFContentStreamRelease(content); content = nil;
    
    _currentPageParsingInProgress = NO;
}

- (void) scanDocumentStartingFromPage:(NSUInteger)pageNumber {
    
	// Return immediately if no keyword set
	if (!keyword) return;
    
    // Init
    _searchFinished = NO;
	_currentPage = pageNumber;
	_initialPage = pageNumber;
    
    // Handle the error just in case
	if (_initialPage > _numberOfPages) {
		return;
	}
    
    // reset the dic
    [self.selectionsDic removeAllObjects];
    
    // create a thread to start searching
	[_searchThread cancel];
	[_searchThread autorelease];
	_searchThread = [[NSThread alloc] initWithTarget:self selector:@selector(_scanDocumentInBackground) object:nil];
	[_searchThread start];

}

- (void) cancelScanning {
	if (![_searchThread isFinished] || ![_searchThread isCancelled]) {
        self.renderingStateStack = nil;
        self.fontCollection = nil;
        self.stringDetector = nil;
        _searchFinished = YES;
        _currentPageParsingInProgress = NO;
        [_searchThread cancel];
	}
}

#define TEXT_LENGTH_TO_SHOW 150 // nb of characters

- (void) _scanDocumentInBackground
{    
    NSMutableString *contentString = [NSMutableString string];
	[self setRawTextContent:&contentString];
    
	while (!_searchFinished)
    {
        _currentPageParsingInProgress = YES;
        [self scanDocumentPage:_currentPage];
        
        while (_currentPageParsingInProgress) {
            // Do nothing, wait !
        }

        // now find the text around
        NSArray *arrayOfSelections = [selectionsDic objectForKey:[NSNumber numberWithUnsignedInteger:_currentPage]];
        if ([arrayOfSelections count] != 0) {
            
            NSInteger totalCharactersCount = TEXT_LENGTH_TO_SHOW + [*rawTextContent length];
            NSInteger sideNumberOfCharacters = totalCharactersCount / 2;
            
            NSRange searchRange = NSMakeRange(0, [*self.rawTextContent length]);
			
			NSRange range = [*self.rawTextContent rangeOfString:self.keyword options:NSCaseInsensitiveSearch range:searchRange];
            
            int currentSelectionIndex = 0;
            
			while (range.location != NSNotFound) {
                
				MHPDFSelection *selection = (MHPDFSelection*)[arrayOfSelections objectAtIndex:currentSelectionIndex];
				
				// gestion du texte autour
				NSInteger leftStart, rightEnd;
				if (range.location > sideNumberOfCharacters)
					leftStart = range.location - sideNumberOfCharacters;
				else
					leftStart = 0;
				
				if (range.location + range.length + sideNumberOfCharacters < [*self.rawTextContent length])
					rightEnd = range.location + range.length + sideNumberOfCharacters;
				else
					rightEnd = [*self.rawTextContent length];
				
                
				// Substring to get the text around
				NSString *stringAroundSearch = [[NSString stringWithString:*self.rawTextContent] substringWithRange:NSMakeRange(leftStart, rightEnd-leftStart)];
				
				// search the first space on the left
				NSRange leftRange = [stringAroundSearch rangeOfString:@" "];
				if (leftRange.location != NSNotFound) {
					NSInteger startRange = leftRange.location + leftRange.length;
					stringAroundSearch = [stringAroundSearch substringWithRange:NSMakeRange(startRange, [stringAroundSearch length] - startRange)];
				}
				
				// search the first space on the right
				NSRange rightRange = [stringAroundSearch rangeOfString:@" " options:NSBackwardsSearch range:NSMakeRange(0, [stringAroundSearch length])];
 				if (rightRange.location != NSNotFound) {
					NSInteger startRange = 0;
					stringAroundSearch = [stringAroundSearch substringWithRange:NSMakeRange(startRange, rightRange.location)];
				}
				
				selection.textAroundSearch = stringAroundSearch;
                
				NSInteger startSearch = range.location + range.length;
				searchRange = NSMakeRange(startSearch, [*self.rawTextContent length] - startSearch);
				range = [*self.rawTextContent rangeOfString:self.keyword options:NSCaseInsensitiveSearch range:searchRange];
                currentSelectionIndex ++;
				
			}
            [self callDelegateOnMainThread:@selector(mhPDFScanner:didFoundNewResults:) withArg:self secondArg:arrayOfSelections];
        }
        else
            [self callDelegateOnMainThread:@selector(mhPDFScanner:didNotFoundResultInPage:) withArg:self secondArg:[NSNumber numberWithUnsignedInteger:_currentPage]];
        
        
        NSMutableString *contentString = [NSMutableString string];
        [self setRawTextContent:&contentString];
        // update new page
		_currentPage ++;
		
		if (_currentPage > _numberOfPages) {
			_currentPage = 1;
		}
        
		if (_currentPage == 1) {
			_searchFinished = YES;
        }
    }

    NSInteger totalNumberOfResults = 0;
    for (id key in self.selectionsDic)
    {
        totalNumberOfResults += ((NSArray*)[self.selectionsDic objectForKey:key]).count;
    }
    
    [self callDelegateOnMainThread:@selector(mhPDFScanner:didFinishSearchingInDocumentWithTotalResult:) withArg:self secondArg:[NSNumber numberWithInteger:totalNumberOfResults]];
}

#pragma mark StringDetectorDelegate

- (void)detector:(MHPDFStringDetector *)detector didScanCharacter:(unichar)character
{
	MHPDFRenderingState *state = [self currentRenderingState];
	CGFloat width = [self.currentFont widthOfCharacter:character withFontSize:state.fontSize];
	width /= 1000;
	width += state.characterSpacing;
	if (character == 32)
	{
		width += state.wordSpacing;
	}
	[state translateTextPosition:CGSizeMake(width, 0)];
}

- (void)detector:(MHPDFStringDetector *)detector didStartMatchingString:(NSString *)string
{
	MHPDFSelection *sel = [[MHPDFSelection alloc] initWithStartState:self.currentRenderingState];
    sel.pageNumber = _currentPage;
	self.currentSelection = sel;
	[sel release];
}

- (void)detector:(MHPDFStringDetector *)detector foundString:(NSString *)needle
{	
	MHPDFRenderingState *state = [[self renderingStateStack] topRenderingState];
	[self.currentSelection finalizeWithState:state];

	if (self.currentSelection)
	{
        NSMutableArray *arrayForPage = [self.selectionsDic objectForKey:[NSNumber numberWithUnsignedInteger:self.currentSelection.pageNumber]];
        if (!arrayForPage) {
            arrayForPage = [NSMutableArray array];
            [self.selectionsDic setObject:arrayForPage forKey:[NSNumber numberWithUnsignedInteger:self.currentSelection.pageNumber]];
        }
		[arrayForPage addObject:self.currentSelection];
		self.currentSelection = nil;
	}
    
    _currentPageParsingInProgress = NO;
}

#pragma mark - Scanner callbacks

void BT(CGPDFScannerRef scanner, void *info)
{
	[[(MHPDFScanner *)info currentRenderingState] setTextMatrix:CGAffineTransformIdentity replaceLineMatrix:YES];
}

/* Pops the requested number of values, and returns the number of values popped */
// !!!: Make sure this is correct, then use it
int popIntegers(CGPDFScannerRef scanner, CGPDFInteger *buffer, size_t length)
{
    bzero(buffer, length);
    CGPDFInteger value;
    int i = 0;
    while (i < length)
    {
        if (!CGPDFScannerPopInteger(scanner, &value)) break;
        buffer[i] = value;
        i++;
    }
    return i;
}

#pragma mark Text showing operators

void didScanSpace(float value, MHPDFScanner *scanner)
{
    float width = [scanner.currentRenderingState convertToUserSpace:value];
    [scanner.currentRenderingState translateTextPosition:CGSizeMake(-width, 0)];
    if (abs(value) >= [scanner.currentRenderingState.font widthOfSpace])
    {
		if (scanner.rawTextContent)
		{
			[*scanner.rawTextContent appendString:@" "];
		}
        [scanner.stringDetector reset];
    }
}

/* Called any time the scanner scans a string */
void didScanString(CGPDFStringRef pdfString, MHPDFScanner *scanner)
{
	NSString *string = [[scanner stringDetector] appendPDFString:pdfString withFont:[scanner currentFont]];
	if (scanner.rawTextContent && string)
	{
        [*scanner.rawTextContent appendFormat:@"%@", string];
	}
}

/* Show a string */
void Tj(CGPDFScannerRef scanner, void *info)
{
	CGPDFStringRef pdfString = nil;
	if (!CGPDFScannerPopString(scanner, &pdfString)) return;
	didScanString(pdfString, info);
}

/* Equivalent to operator sequence [T*, Tj] */
void quot(CGPDFScannerRef scanner, void *info)
{
	TStar(scanner, info);
	Tj(scanner, info);
}

/* Equivalent to the operator sequence [Tw, Tc, '] */
void doubleQuot(CGPDFScannerRef scanner, void *info)
{
	Tw(scanner, info);
	Tc(scanner, info);
	quot(scanner, info);
}

/* Array of strings and spacings */
void TJ(CGPDFScannerRef scanner, void *info)
{
	CGPDFArrayRef array = nil;
	CGPDFScannerPopArray(scanner, &array);
    size_t count = CGPDFArrayGetCount(array);
    
	for (int i = 0; i < count; i++)
	{
		CGPDFObjectRef object = nil;
		CGPDFArrayGetObject(array, i, &object);
		CGPDFObjectType type = CGPDFObjectGetType(object);

        switch (type)
        {
            case kCGPDFObjectTypeString:
            {
                CGPDFStringRef pdfString = nil;
                CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString);
                didScanString(pdfString, info);
                break;
            }
            case kCGPDFObjectTypeReal:
            {
                CGPDFReal tx = 0.0f;
                CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &tx);
                didScanSpace(tx, info);
                break;
            }
            case kCGPDFObjectTypeInteger:
            {
                CGPDFInteger tx = 0L;
                CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &tx);
                didScanSpace(tx, info);
                break;
            }
            default:
                NSLog(@"Scanner: TJ: Unsupported type: %d", type);
                break;
        }
	}
}

#pragma mark Text positioning operators

/* Move to start of next line */
void Td(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal tx = 0, ty = 0;
	CGPDFScannerPopNumber(scanner, &ty);
	CGPDFScannerPopNumber(scanner, &tx);
	[[(MHPDFScanner *)info currentRenderingState] newLineWithLeading:-ty indent:tx save:NO];
}

/* Move to start of next line, and set leading */
void TD(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal tx, ty;
	if (!CGPDFScannerPopNumber(scanner, &ty)) return;
	if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	[[(MHPDFScanner *)info currentRenderingState] newLineWithLeading:-ty indent:tx save:YES];
}

/* Set line and text matrixes */
void Tm(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal a, b, c, d, tx, ty;
	if (!CGPDFScannerPopNumber(scanner, &ty)) return;
	if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	if (!CGPDFScannerPopNumber(scanner, &d)) return;
	if (!CGPDFScannerPopNumber(scanner, &c)) return;
	if (!CGPDFScannerPopNumber(scanner, &b)) return;
	if (!CGPDFScannerPopNumber(scanner, &a)) return;
	CGAffineTransform t = CGAffineTransformMake(a, b, c, d, tx, ty);
	[[(MHPDFScanner *)info currentRenderingState] setTextMatrix:t replaceLineMatrix:YES];
}

/* Go to start of new line, using stored text leading */
void TStar(CGPDFScannerRef scanner, void *info)
{
	[[(MHPDFScanner *)info currentRenderingState] newLine];
}

#pragma mark Text State operators

/* Set character spacing */
void Tc(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal charSpace;
	if (!CGPDFScannerPopNumber(scanner, &charSpace)) return;
	[[(MHPDFScanner *)info currentRenderingState] setCharacterSpacing:charSpace];
}

/* Set word spacing */
void Tw(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal wordSpace;
	if (!CGPDFScannerPopNumber(scanner, &wordSpace)) return;
	[[(MHPDFScanner *)info currentRenderingState] setWordSpacing:wordSpace];
}

/* Set horizontal scale factor */
void Tz(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal hScale;
	if (!CGPDFScannerPopNumber(scanner, &hScale)) return;
	[[(MHPDFScanner *)info currentRenderingState] setHorizontalScaling:hScale];
}

/* Set text leading */
void TL(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal leading;
	if (!CGPDFScannerPopNumber(scanner, &leading)) return;
	[[(MHPDFScanner *)info currentRenderingState] setLeadning:leading];
}

/* Font and font size */
void Tf(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal fontSize;
	const char *fontName;
	if (!CGPDFScannerPopNumber(scanner, &fontSize)) return;
	if (!CGPDFScannerPopName(scanner, &fontName)) return;
	
	MHPDFRenderingState *state = [(MHPDFScanner *)info currentRenderingState];
	MHPDFFont *font = [[(MHPDFScanner *)info fontCollection] fontNamed:[NSString stringWithUTF8String:fontName]];
	[state setFont:font];
	[state setFontSize:fontSize];
}

/* Set text rise */
void Ts(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal rise;
	if (!CGPDFScannerPopNumber(scanner, &rise)) return;
	[[(MHPDFScanner *)info currentRenderingState] setTextRise:rise];
}


#pragma mark Graphics state operators

/* Push a copy of current rendering state */
void q(CGPDFScannerRef scanner, void *info)
{
	RenderingStateStack *stack = [(MHPDFScanner *)info renderingStateStack];
	MHPDFRenderingState *state = [[(MHPDFScanner *)info currentRenderingState] copy];
	[stack pushRenderingState:state];
	[state release];
}

/* Pop current rendering state */
void Q(CGPDFScannerRef scanner, void *info)
{
	[[(MHPDFScanner *)info renderingStateStack] popRenderingState];
}

/* Update CTM */
void cm(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal a, b, c, d, tx, ty;
	if (!CGPDFScannerPopNumber(scanner, &ty)) return;
	if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	if (!CGPDFScannerPopNumber(scanner, &d)) return;
	if (!CGPDFScannerPopNumber(scanner, &c)) return;
	if (!CGPDFScannerPopNumber(scanner, &b)) return;
	if (!CGPDFScannerPopNumber(scanner, &a)) return;
	
	MHPDFRenderingState *state = [(MHPDFScanner *)info currentRenderingState];
	CGAffineTransform t = CGAffineTransformMake(a, b, c, d, tx, ty);
	state.ctm = CGAffineTransformConcat(state.ctm, t);
}

#pragma mark - Delegate Mananagement

- (void) callDelegate: (SEL) selector withArg: (id) arg secondArg: (id) secondArg
{
    //assert([NSThread isMainThread]);
    if([self.delegate respondsToSelector: selector])
    {
        if(arg != nil)
        {
            [self.delegate performSelector: selector withObject: arg withObject: secondArg];
        }
        else
        {
            [self.delegate performSelector: selector withObject: secondArg];
        }
    }
}


- (void) callDelegateOnMainThread: (SEL) selector withArg: (id) arg secondArg: (id) secondArg
{    
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    float systemVersionF = [systemVersion floatValue];
    if (systemVersionF >= 4.0 ) {
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           [self callDelegate: selector withArg: arg secondArg: secondArg];
                       });
    }
    else {
        [self callDelegate: selector withArg: arg secondArg: secondArg];
    }
    
}

#pragma mark -
#pragma mark Memory management

- (RenderingStateStack *)renderingStateStack
{
	if (!renderingStateStack)
	{
		renderingStateStack = [[RenderingStateStack alloc] init];
	}
	return renderingStateStack;
}

- (MHPDFStringDetector *)stringDetector
{
	if (!stringDetector)
	{
		stringDetector = [[MHPDFStringDetector alloc] initWithKeyword:self.keyword];
		stringDetector.delegate = self;
	}
	return stringDetector;
}

- (NSMutableDictionary *)selectionsDic
{
	if (!selectionsDic)
	{
		selectionsDic = [[NSMutableDictionary alloc] init];
	}
	return selectionsDic;
}

- (NSMutableArray*)selections {
    NSLog(@"MHPDF Warning : Please use selectionsDic instead of selections");
    if ([selectionsDic allKeys].count != 0)
        return [selectionsDic objectForKey:[[selectionsDic allKeys] objectAtIndex:0]];
    else
        return nil;
}

- (void)dealloc
{
	CGPDFOperatorTableRelease(operatorTable);
	[currentSelection release];
	[fontCollection release];
	[renderingStateStack release];
	[keyword release]; keyword = nil;
	[stringDetector release];
	[documentURL release]; documentURL = nil;
	CGPDFDocumentRelease(pdfDocument); pdfDocument = nil;
	[super dealloc];
}

@synthesize documentURL, keyword, stringDetector, fontCollection, renderingStateStack, currentSelection, selectionsDic, rawTextContent, delegate, selections;
@end
