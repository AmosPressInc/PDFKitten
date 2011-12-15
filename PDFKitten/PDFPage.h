#import "Page.h"
#import "MHPDFScanner.h"


@interface PDFContentView : PageContentView {
	CGPDFPageRef pdfPage;
    NSString *keyword;
	NSArray *selections;
	MHPDFScanner *scanner;
    NSUInteger _pageNumber;
}

#pragma mark

- (void)setPage:(CGPDFPageRef)page;

@property (nonatomic, retain) MHPDFScanner *scanner;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSArray *selections;

@end

#pragma mark

@interface PDFPage : Page {
}

#pragma mark

- (void)setPage:(CGPDFPageRef)page;

@property (nonatomic, copy) NSString *keyword;

@end
