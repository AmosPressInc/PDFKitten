#import <Foundation/Foundation.h>
#import "MHPDFFont.h"

@interface MHPDFFontCollection : NSObject {
	NSMutableDictionary *fonts;
	NSArray *names;
}

/* Initialize with a font collection dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict;

/* Return the specified font */
- (MHPDFFont *)fontNamed:(NSString *)fontName;

@property (nonatomic, readonly) NSDictionary *fontsByName;

@property (nonatomic, readonly) NSArray *names;

@end
