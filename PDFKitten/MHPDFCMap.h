#import <Foundation/Foundation.h>


@interface MHPDFCMap : NSObject {
	NSMutableArray *offsets;
    NSMutableDictionary *chars;
}

/* Initialize with PDF stream containing a CMap */
- (id)initWithPDFStream:(CGPDFStreamRef)stream;

/* Unicode mapping for character ID */
- (unichar)unicodeCharacter:(unichar)cid;

@end