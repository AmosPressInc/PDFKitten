#import <UIKit/UIKit.h>
#import "MHPDFFontCollection.h"

@interface PDFPageDetailsView : UINavigationController <UITableViewDelegate, UITableViewDataSource> {
	MHPDFFontCollection *fontCollection;
}

- (id)initWithFont:(MHPDFFontCollection *)fontCollection;

@end
