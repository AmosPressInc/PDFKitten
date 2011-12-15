#import "RootViewController.h"  
#import "PDFPage.h"
#import "DocumentsView.h"
#import "MHPDFScanner.h"
#import "PDFPageDetailsView.h"

@implementation RootViewController

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
        NSURL *pdfURL = [NSURL fileURLWithPath:self.documentPath];
        document = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
	}
	return self;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController isEqual:libraryPopover])
    {
        [libraryPopover release]; libraryPopover = nil;
    }
}

- (void)didSelectDocument:(NSURL *)url
{
	[libraryPopover dismissPopoverAnimated:YES];
	[libraryPopover release]; libraryPopover = nil;
	
	CGPDFDocumentRelease(document);
	document = CGPDFDocumentCreateWithURL((CFURLRef)url);
	[pageView reloadData];
}

- (IBAction)showLibraryPopover:(UIBarButtonItem *)sender
{
    if (libraryPopover)
    {
        [libraryPopover dismissPopoverAnimated:NO];
        [libraryPopover release]; libraryPopover = nil;
        return;
    }
    
    DocumentsView *docView = [[[DocumentsView alloc] init] autorelease];
	docView.delegate = self;
    libraryPopover = [[UIPopoverController alloc] initWithContentViewController:docView];
    libraryPopover.delegate = self;
    [libraryPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// Ask user to connect Dropbox account
//	DBLoginController *loginController = [[DBLoginController new] autorelease];
//	[loginController presentFromController:self];
}

#pragma mark PageViewDelegate

/* The number of pages in the current PDF document */
- (NSInteger)numberOfPagesInPageView:(PageView *)pageView
{
	return CGPDFDocumentGetNumberOfPages(document);
}

- (MHPDFFontCollection *)activeFontCollection
{
	Page *page = [pageView pageAtIndex:pageView.page];
	PDFContentView *pdfPage = (PDFContentView *) [(PDFPage *) page contentView];
	return [[pdfPage scanner] fontCollection];
}

/* Return the detailed view corresponding to a page */
- (UIView *)pageView:(PageView *)aPageView detailedViewForPage:(NSInteger)page
{
	MHPDFScanner *scanner = [[MHPDFScanner alloc] init];
	[scanner setKeyword:@""];
	NSMutableString *contentString = [NSMutableString string];
	[scanner setRawTextContent:&contentString];
	CGPDFPageRef pdfpage = CGPDFDocumentGetPage(document, page+1);
	[scanner scanPage:pdfpage];
	[scanner release];

	MHPDFFontCollection *collection = [self activeFontCollection];
	PDFPageDetailsView *detailedView = [[PDFPageDetailsView alloc] initWithFont:collection];
	return [detailedView view];
}

// TODO: Assign page to either the page or its content view, not both.

/* Page view object for the requested page */
- (Page *)pageView:(PageView *)aPageView viewForPage:(NSInteger)pageNumber
{
	PDFPage *page = (PDFPage *) [aPageView dequeueRecycledPage];
	if (!page)
	{
		page = [[[PDFPage alloc] initWithFrame:CGRectZero] autorelease];
	}
    
	page.pageNumber = pageNumber;
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(document, pageNumber + 1); // PDF document page numbers are 1-based
    [page setPage:pdfPage];
	page.keyword = keyword;
    
	return page;
}

- (NSString *)keywordForPageView:(PageView *)pageView
{
	return keyword;
}

// TODO: add user interface for choosing document

- (NSString *)documentPath
{
    // DEBUG: for now, always load Kurt the Cat
	return [[NSBundle mainBundle] pathForResource:@"Kurt the Cat" ofType:@"pdf"];
}

#pragma mark Search

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
	[keyword release];
	keyword = [[aSearchBar text] retain];
	[pageView setKeyword:keyword];
	
    if(!_testBGScanner)
        _testBGScanner = [[MHPDFScanner alloc] initWithDocument:document];
    [_testBGScanner cancelScanning];
    _testBGScanner.delegate = self;
    [_testBGScanner setKeyword:keyword];
    
    [self performSelector:@selector(startNewSearch) withObject:nil afterDelay:0.3];

	[aSearchBar resignFirstResponder];
}

- (void) startNewSearch {
    [_testBGScanner scanDocumentStartingFromPage:1];
}

#pragma mark - MHPDFScannerDelegate 
- (void) mhPDFScanner:(MHPDFScanner *)searcher didFinishSearchingInDocumentWithTotalResult:(NSNumber *)totalResult {
    NSLog(@"Finish = %d", [totalResult intValue]);    
}

- (void) mhPDFScanner:(MHPDFScanner *)scanner didFoundNewResults:(NSArray *)newResults {
    NSLog(@"******************");
    NSLog(@"%@", newResults);
}

- (void) mhPDFScanner:(MHPDFScanner *)searcher didNotFoundResultInPage:(NSNumber *)page {
    NSLog(@"nothing found in %d", [page intValue]);
}

#pragma mark Memory Management

- (void)dealloc
{
    CGPDFDocumentRelease(document);
    [super dealloc];
}

@end
