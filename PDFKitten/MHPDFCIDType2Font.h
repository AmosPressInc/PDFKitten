#import <Foundation/Foundation.h>
#import "MHPDFCompositeFont.h"

@interface MHPDFCIDType2Font : MHPDFCompositeFont {
	BOOL identity;
}

@property (nonatomic, assign, getter = isIdentity) BOOL identity;
@end
