#import "PageViewController.h"
#import "PageView.h"
#import "MHPDFScanner.h"

@interface RootViewController : UIViewController <PageViewDelegate, UIPopoverControllerDelegate, UISearchBarDelegate> {
	CGPDFDocumentRef document;
    UIPopoverController *libraryPopover;
	IBOutlet PageView *pageView;
	IBOutlet UISearchBar *searchBar;
	NSString *keyword;
    
    MHPDFScanner *_testBGScanner;
}

@property (nonatomic, readonly) NSString *documentPath;
@end
