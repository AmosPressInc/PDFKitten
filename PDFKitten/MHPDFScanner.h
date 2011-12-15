#import <Foundation/Foundation.h>
#import "MHPDFStringDetector.h"
#import "MHPDFFontCollection.h"
#import "MHPDFRenderingState.h"
#import "MHPDFSelection.h"

@interface MHPDFScanner : NSObject <StringDetectorDelegate> {
	NSURL *documentURL;
	NSString *keyword;
	CGPDFDocumentRef pdfDocument;
	CGPDFOperatorTableRef operatorTable;
	MHPDFStringDetector *stringDetector;
	MHPDFFontCollection *fontCollection;
	RenderingStateStack *renderingStateStack;
	MHPDFSelection *currentSelection;
	NSMutableDictionary *selectionsDic;
	NSMutableString **rawTextContent;
    
    NSUInteger _initialPage;
    NSUInteger _currentPage;
    NSUInteger _numberOfPages;
    NSThread *_searchThread;

    BOOL _currentPageParsingInProgress;
    BOOL _searchFinished;

}

/* Initialize with a file path */
- (id)initWithContentsOfFile:(NSString *)path;

/* Initialize with a PDF document */
- (id)initWithDocument:(CGPDFDocumentRef)document;

/* Start scanning (synchronous) */
- (void)scanDocumentPage:(NSUInteger)pageNumber;

/* Start scanning a particular page */
- (void)scanPage:(CGPDFPageRef)page;

/* Start scanning from a Page */
- (void)scanDocumentStartingFromPage:(NSUInteger) pageNumber;

/* Cancel the scanning */
- (void) cancelScanning;

/* We use an NSDictionary to avoid NSPredicates when accessing specifics Selections for Pages */
@property (nonatomic, retain) NSMutableDictionary *selectionsDic;
@property (nonatomic, retain) RenderingStateStack *renderingStateStack;
@property (nonatomic, retain) MHPDFFontCollection *fontCollection;
@property (nonatomic, retain) MHPDFStringDetector *stringDetector;
@property (nonatomic, retain) NSString *keyword;
@property (nonatomic, assign) NSMutableString **rawTextContent;
@end
